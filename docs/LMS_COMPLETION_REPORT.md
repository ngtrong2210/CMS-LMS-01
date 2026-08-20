# Hoàn thiện luồng LMS theo môn học lớp

## Mô hình nghiệp vụ chuẩn

Hệ thống không còn yêu cầu giáo viên tạo một khóa học trực tuyến độc lập. Nội dung học tập được mở theo cấu trúc:

`Năm học → Lớp → Môn học lớp → Chương → Bài học → Hoạt động học tập`

`SIM_Class_Subject` là đơn vị phân công giảng dạy theo năm và học kỳ. Mỗi bản ghi có tối đa một không gian nội dung trong `SIM_Courses`, liên kết bằng `ClassSubjectID`. Giáo viên được phân công hoặc quản trị viên mới được soạn nội dung.

Khi nhấn **Soạn bài**, thủ tục `LMS_ClassSubject_Workspace_Ensure` sẽ:

1. Kiểm tra môn học lớp và quyền giáo viên.
2. Tạo không gian nội dung nếu chưa có.
3. Tự động ghi danh các học viên đang thuộc lớp.
4. Trả về `CourseID` để mở trang soạn chương và bài.

## Các loại bài học

- `VIDEO`: video tải lên hoặc YouTube, có câu hỏi tương tác và tiến độ xem.
- `DOCUMENT`: tài liệu PDF/DOCX/PPTX được lưu trong `Media/File`.
- `EDITOR`: nội dung HTML do giáo viên soạn; phía học viên luôn hiển thị qua bộ lọc HTML an toàn.
- `ASSIGNMENT`: bài tập có thời gian mở, hạn nộp, số lần nộp, dung lượng file và điểm tối đa.
- `QUIZ`: giáo viên chọn câu từ ngân hàng, cấu hình điểm đạt/thời gian/lượt làm; backend giữ đáp án và tự chấm khi học viên nộp.

## Luồng bài tập và chấm điểm

Học viên có thể lưu nháp nhiều lần trước khi nộp. Khi nộp, hệ thống kiểm tra ghi danh, thời gian mở, hạn nộp, chính sách nộp trễ, số lần nộp và giới hạn file ở backend. Metadata bài nộp nằm tại `LMS_AssignmentSubmissions`; file đính kèm tách tại `LMS_AssignmentSubmissionFiles`.

Giảng viên dùng trang `/cms/assignments` để lọc theo môn học lớp/trạng thái, xem nội dung, tải file, nhập điểm, phản hồi hoặc trả bài bổ sung. Điểm đã chấm được đồng bộ vào `LMS_StudentLessonProgress` và xuất hiện trong kết quả học viên/báo cáo.

## Theo dõi thời gian học

`LMS_StudySessions` ghi phiên học bằng heartbeat. Backend chỉ tính khoảng heartbeat hợp lệ, đóng phiên trùng của cùng học viên và bài học, sau đó cộng một lần vào `LMS_StudentLessonProgress.ActiveStudySeconds`. Trình duyệt không gửi heartbeat khi tab bị ẩn hoặc người dùng không còn hoạt động.

## API bổ sung

- `POST /api/academic/class-subjects/{id}/workspace`: tạo hoặc lấy không gian soạn của môn học lớp.
- `PUT /api/lms/lessons/{id}/submission-draft`: lưu nháp bài làm.
- `POST /api/lms/lessons/{id}/submissions`: nộp bài.
- `GET /api/teaching/assignment-submissions`: danh sách bài nộp thuộc quyền giảng viên.
- `PUT /api/teaching/assignment-submissions/{id}/grade`: chấm điểm hoặc trả bổ sung.
- `GET|PUT /api/lessons/{id}/quiz`: tải và lưu cấu hình quiz cho giáo viên.
- `GET /api/lms/lessons/{id}/quiz`: tải đề không chứa đáp án đúng.
- `POST /api/lms/lessons/{id}/quiz-attempts`: bắt đầu lượt làm.
- `POST /api/lms/quiz-attempts/{id}/submit`: nộp và chấm quiz hoàn toàn tại backend.

## Migration và dữ liệu mẫu

- `009_CompleteClassSubjectLearningFlow.sql`: mở rộng cấu hình bài tập, file bài nộp và tổng hợp thời gian học.
- `010_ClassSubjectContentDemoData.sql`: tạo không gian nội dung, chương mở đầu, bài đọc, bài tập và bài nộp mẫu cho các môn học lớp hiện có. Script dùng `Not Exists`, vì vậy có thể chạy lại an toàn.
- `011_QuizLearningFlow.sql`: tạo quiz, câu hỏi trong quiz, lượt làm, đáp án từng lượt và gắn dữ liệu mẫu từ ngân hàng câu hỏi.

## Kết quả kiểm tra

- Database initializer chạy thành công trên SQL Server thực.
- Backend build không cảnh báo/lỗi.
- Frontend production build thành công.
- Unit test backend: 2/2 đạt.
- Test frontend: 17/17 đạt.
- Integration test API/SQL: 35/35 đạt.
