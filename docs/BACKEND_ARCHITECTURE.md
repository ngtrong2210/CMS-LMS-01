# Kiến trúc backend Sims .NET 8

Backend được chuẩn hóa theo cấu trúc quen thuộc `SimsObject` và `SimsService`, đồng thời tách riêng phần kỹ thuật dữ liệu trong `SimsData`.

```text
Frontend bất kỳ (Vue, React, mobile, Web Forms...)
                         |
                         v
                     Sims.Api
                         |
                         v
                   SimsService
                    /         \
                   v           v
             SimsObject     SimsData
                                |
                                v
                    SQL Server + Stored Procedure
```

## Trách nhiệm từng project

### SimsObject

- Entity và object dùng chung.
- DTO, request và response của API.
- Interface/contract mà Service và Data cùng sử dụng.
- Validation và kiểu kết quả dùng chung.
- Không chứa controller, kết nối SQL hoặc xử lý file vật lý.

Thư mục `Base` được dành cho object sinh tự động từ cấu trúc bảng. Phần mở rộng tự viết đặt ngoài `Base` bằng `partial class` để không bị ghi đè khi sinh lại.

### SimsService

- Toàn bộ service nghiệp vụ của LMS/CMS.
- Kiểm tra điều kiện nghiệp vụ trước khi gọi stored procedure.
- Điều phối nghiệp vụ học tập, video, câu hỏi, bài kiểm tra và bài nộp.
- Đăng ký Dependency Injection qua `AddSimsServices()`.

### SimsData

- Tạo kết nối SQL Server.
- Khởi tạo database khi được yêu cầu.
- Lưu trữ file trong `Media` và thư mục tạm của project.
- JWT token, health check và các adapter kỹ thuật.
- Không chứa controller hoặc giao diện.

### Sims.Api

- ASP.NET Core API .NET 8.
- Controller, middleware, filter, authentication và Swagger.
- Giữ controller mỏng; nghiệp vụ phải được chuyển xuống `SimsService`.
- Không gọi SQL trực tiếp.

## Quy tắc phụ thuộc

```text
SimsObject  -> không phụ thuộc project nội bộ nào
SimsData    -> SimsObject
SimsService -> SimsObject + SimsData
Sims.Api    -> SimsObject + SimsService + SimsData
```

Không tạo tham chiếu ngược từ `SimsObject` sang `SimsService`, hoặc từ `SimsData` sang `SimsService`.

## Nguyên tắc tương thích

- Giữ nguyên route API để frontend hiện tại không phải sửa.
- Giữ nguyên tên bảng, stored procedure, tham số và dữ liệu SQL.
- Giữ nguyên cấu trúc `/Media`; package deploy không ghi đè dữ liệu upload production.
- Object sinh từ bảng dùng mẫu `Base/<TableName>Base.cs` và `<TableName>.cs`.
- Nghiệp vụ nhiều bảng gọi stored procedure có transaction, không ghép nhiều CRUD rời rạc tại controller.
- DTO API phải khai báo rõ kiểu; hạn chế thêm mới kết quả `object` hoặc dynamic.

## Lệnh phát triển

```powershell
dotnet build .\Sims.sln
dotnet test .\Sims.sln --no-build
dotnet run --project .\src\Sims.Api\Sims.Api.csproj --launch-profile http
```

## Điểm quay lại trước khi chuẩn hóa

- Commit: `a6a91b8`
- Tag: `backup-pre-sims-refactor-20260822`
- Branch: `codex/backup-pre-sims-refactor-20260822`
