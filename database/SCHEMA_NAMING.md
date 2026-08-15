# Quy ước tên schema LMS/CMS

## Prefix theo phân hệ

| Prefix | Phạm vi | Ví dụ |
|---|---|---|
| `SYS_` | Tài khoản, vai trò, quyền, token, nhật ký hệ thống | `SYS_Users`, `SYS_Roles` |
| `SIM_` | Thông tin khóa học, cấu trúc nội dung, thư viện học liệu | `SIM_Courses`, `SIM_Lessons`, `SIM_VideoAssets` |
| `LMS_` | Ghi danh, quá trình học, tương tác, câu trả lời, điểm và tiến độ | `LMS_Enrollments`, `LMS_StudentAnswers` |
| `CRM_` | Dành cho khách hàng tiềm năng, tư vấn tuyển sinh, chiến dịch chăm sóc khi phân hệ này được bổ sung | `CRM_Leads` |
| `HRM_` | Dành cho hồ sơ nhân sự, hợp đồng, phòng ban khi phân hệ này được bổ sung | `HRM_Employees` |

Không gắn `CRM_` hoặc `HRM_` cho bảng hiện tại nếu dữ liệu không thuộc đúng nghiệp vụ. Tài khoản đăng nhập của giảng viên và học viên vẫn là `SYS_Users`; hồ sơ nhân sự mở rộng trong tương lai mới thuộc `HRM_`.

## Quy ước cột định danh

- Không dùng tên chung `Id` trong bảng vật lý.
- Khóa chính mang tên thực thể: `UserID`, `CourseID`, `QuestionID`, `VideoID`.
- Khóa ngoại giữ đúng tên khóa được tham chiếu; thêm vai trò khi cần làm rõ: `TeacherUserID`, `StudentUserID`, `CreatedByUserID`.
- Hậu tố `ID` được viết thống nhất để dễ tìm kiếm trong SQL Server.

## Tương thích logic hiện tại

Migration `001_NormalizeSchemaNames.sql` đổi tên trực tiếp bằng `sp_rename`, vì vậy dữ liệu, khóa ngoại, index và extended property không bị tạo lại. Các view tên cũ (`Users`, `Courses`, `StudentAnswers`,...) chỉ là lớp tương thích tạm thời cho stored procedure và API hiện hữu; bảng vật lý trong SQL Server chỉ còn tên chuẩn theo module.

Mọi bảng và cột vật lý bắt buộc có `MS_Description`. Migration sẽ kiểm tra và dừng nếu còn bảng sai prefix, cột `Id` chung hoặc cột thiếu description.
