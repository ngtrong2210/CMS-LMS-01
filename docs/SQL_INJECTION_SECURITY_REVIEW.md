# SQL Injection Security Review

Ngày rà soát: 21/08/2026

## Phạm vi

Đã rà soát các lớp Controller, Service, Data Access, middleware, DTO, Stored Procedure và migration có liên quan đến:

- Đăng nhập, người dùng và phân quyền.
- Khóa học, chương, bài học và cấu trúc đào tạo.
- Video tương tác, bài đọc tương tác, câu hỏi và câu trả lời.
- Bài tập, bài nộp, nhận xét của giáo viên.
- Bình luận và trả lời bình luận.
- Tiến độ, phiên học, tìm kiếm, bộ lọc và phân trang.

## Kết quả định lượng

| Hạng mục | Kết quả |
| --- | ---: |
| Điểm gọi dữ liệu Dapper được rà soát | 81 |
| Định nghĩa Stored Procedure được rà soát | 132 |
| Tổng vị trí thực thi/định nghĩa SQL đã kiểm tra | 213 |
| Query runtime nối trực tiếp input người dùng vào SQL | 0 |
| Query phải chuyển từ nối chuỗi sang parameter | 0 |
| Dynamic SQL trong Stored Procedure runtime | 0 |
| Dynamic `ORDER BY` nhận trực tiếp từ request | 0 |
| Bộ chọn tên Stored Procedure động được kiểm soát | 2 |
| Stored Procedure tìm kiếm/bộ lọc được kiểm tra và gia cố wildcard | 6 |
| Security integration test mới | 11 trường hợp |

Toàn bộ dữ liệu động của tầng runtime đang đi qua tham số Dapper/Stored Procedure. Không phát hiện luồng `User Input -> String Concatenation -> SQL` trong mã runtime.

## Các thay đổi bảo mật đã thực hiện

1. Thêm kiểm tra tập trung cho route ID dạng số; ID nhỏ hơn hoặc bằng 0 bị trả về HTTP 400 trước khi đến tầng dữ liệu.
2. Bổ sung giới hạn độ dài, whitelist giá trị filter và kiểm tra danh sách ID dương ở tầng service/DTO.
3. Giới hạn kích thước các collection câu trả lời, câu hỏi, học viên và nội dung bài nộp để tránh truy vấn quá tải.
4. Whitelist 24 tên Stored Procedure mà helper dùng tên lệnh động trong `ContentService` được phép gọi. Bộ chọn báo cáo tiếp tục dùng `switch` ánh xạ sang tên cố định.
5. Escape ký tự wildcard `%`, `_`, `[` tại Stored Procedure tìm kiếm để dữ liệu tìm kiếm được hiểu là dữ liệu literal, không mở rộng phạm vi kết quả ngoài ý muốn.
6. Bổ sung kiểm tra quyền tác giả khi cập nhật/xóa câu hỏi; quản trị viên vẫn có quyền quản lý toàn bộ.
7. Che thông tin SQL nội bộ trong response lỗi. Client chỉ nhận thông báo nghiệp vụ ổn định; log server dùng mã lỗi và Trace ID.
8. Giới hạn file migration được thực thi trong thư mục project đã xác định; tên file/path từ bên ngoài không được dùng làm nguồn script.
9. Nội dung HTML xem trước phía CMS được sanitize riêng để chống XSS. Đây là lớp bảo vệ độc lập với parameterized SQL.
10. Nội dung bài làm được giới hạn độ dài nhưng giữ nguyên ký tự đặc biệt và khoảng trắng người học đã nhập.

## Kiểm tra theo module

| Module | Kết quả |
| --- | --- |
| Login/User | Username/password truyền bằng parameter; mật khẩu kiểm tra bằng BCrypt; payload không bypass đăng nhập. |
| Course/Chapter/Lesson | ID kiểu số, route ID dương, thao tác dữ liệu dùng Stored Procedure parameterized. |
| Video Interactive | Tạo/sửa/xóa tương tác, lấy câu hỏi, lưu câu trả lời và tiến độ dùng parameter; regression test đạt. |
| Interactive Content | Lesson/Question/Option/Attempt và mảng câu trả lời được validate; đáp án chính thức không lộ ra player. |
| Assignment/Submission | ID, nội dung, trạng thái và bộ lọc dùng parameter/whitelist; quyền giáo viên/học viên được kiểm tra. |
| Comment/Reply | LessonID, ParentCommentID, UserID và Content dùng parameter; ký tự `'`, `;`, `--` được lưu như dữ liệu. |
| Search/Filter | Keyword dùng parameter; filter enum được whitelist; wildcard được escape; page size có giới hạn. |
| Sort/Order | Không có cột hoặc chiều sắp xếp động lấy trực tiếp từ request trong tầng runtime. |
| Authorization/IDOR | Identity lấy từ JWT; kiểm tra enrollment, quyền tác giả và vai trò tại các endpoint nhạy cảm. |
| Error/Logging | Không trả tên database, SQL Server, Stored Procedure, connection string hoặc token cho frontend. |

## Payload đã kiểm thử

- `O'Brien`
- `Hôm nay em học phần 'JOIN' trong SQL.`
- `' OR '1'='1`
- `'; SELECT 1; --`
- `%%`

Kết quả: dữ liệu hợp lệ có ký tự đặc biệt được lưu/tìm như dữ liệu; payload không bypass đăng nhập, không mở rộng kết quả tìm kiếm, không làm phát sinh lệnh SQL thứ hai và không thay đổi cấu trúc dữ liệu.

## Kết quả build và test

- Backend Release build: đạt, 0 warning, 0 error.
- Frontend production build: đạt.
- Integration test toàn hệ thống: 46/46 đạt.
- Security integration test nằm trong bộ trên: 11/11 trường hợp đạt.
- Unit test: 8/8 đạt; kiểm tra helper validate, whitelist, ID dương, ký tự đặc biệt và bảo toàn khoảng trắng.

## File bảo mật chính đã thêm/sửa

- `src/LmsCms.Api/Filters/PositiveRouteIdFilter.cs`
- `src/LmsCms.Api/Middleware/GlobalExceptionMiddleware.cs`
- `src/LmsCms.Api/Program.cs`
- `src/LmsCms.Api/Controllers/QuestionsController.cs`
- `src/LmsCms.Application/Common/InputGuard.cs`
- `src/LmsCms.Application/DTOs/Dtos.cs`
- `src/LmsCms.Application/Interfaces/Services.cs`
- `src/LmsCms.Infrastructure/Data/DatabaseInitializer.cs`
- `src/LmsCms.Infrastructure/Services/AcademicService.cs`
- `src/LmsCms.Infrastructure/Services/ContentService.cs`
- `src/LmsCms.Infrastructure/Services/CourseService.cs`
- `src/LmsCms.Infrastructure/Services/LearningService.cs`
- `src/LmsCms.Infrastructure/Services/QuestionService.cs`
- `src/LmsCms.Infrastructure/Services/QuizService.cs`
- `src/LmsCms.Infrastructure/Services/SearchService.cs`
- `src/LmsCms.Infrastructure/Services/StudentService.cs`
- `src/LmsCms.Infrastructure/Services/TeachingService.cs`
- `database/stored-procedures/AcademicCompletion.sql`
- `database/stored-procedures/Content.sql`
- `database/stored-procedures/Courses.sql`
- `database/stored-procedures/Questions.sql`
- `database/stored-procedures/Students.sql`
- `frontend/src/views/cms/ContentBuilderView.vue`
- `tests/LmsCms.IntegrationTests/SecurityTests.cs`
- `tests/LmsCms.IntegrationTests/AssemblyInfo.cs`
- `tests/LmsCms.UnitTests/InputGuardTests.cs`

## Vị trí còn tồn đọng

Không còn vị trí SQL Injection đã xác nhận mà chưa sửa trong phạm vi runtime được rà soát. Các đoạn SQL động trong migration chỉ dựng DDL từ metadata hệ thống/tên định danh cố định và dùng `QUOTENAME`; chúng không nhận input từ HTTP request hoặc người dùng.
