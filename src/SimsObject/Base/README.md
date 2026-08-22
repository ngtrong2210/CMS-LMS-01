# Object Base

Thư mục này dành cho các lớp object được sinh tự động từ cấu trúc bảng SQL.

Quy ước:

- File sinh tự động: `Base/<TableName>Base.cs`.
- File mở rộng tự viết: `../<TableName>.cs`.
- Hai lớp dùng cùng `partial class` khi cần mở rộng.
- Công cụ generate chỉ được ghi đè file trong thư mục `Base`.
- Tên khóa chính giữ rõ nghĩa, ví dụ `UserID`, `StudentID`, `LessonID`.
