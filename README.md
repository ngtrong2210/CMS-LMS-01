# LearnHub LMS/CMS

Hệ thống học tập và quản trị đào tạo gồm Vue 3 + Bootstrap 5, ASP.NET Core .NET 8, Dapper, Stored Procedure và SQL Server.

## Chạy nhanh

### 1. Khởi tạo database

Thiết lập hai biến môi trường `ConnectionStrings__BootstrapConnection` và `ConnectionStrings__DefaultConnection`, sau đó chạy:

```powershell
dotnet run --project src/LmsCms.Api -- --init-db
```

Database `LMSCMS_DB`, bảng, index, stored procedure và demo data sẽ được tạo idempotent.

### 2. Chạy API

```powershell
dotnet run --project src/LmsCms.Api --urls https://localhost:7001
```

Swagger: `https://localhost:7001/swagger`

### 3. Chạy frontend

```powershell
cd frontend
npm install
npm run dev
```

Frontend: `http://localhost:5173`

Mặc định frontend chạy mock mode. Đổi `VITE_DATA_MODE=api` trong `.env.development` để gọi API.

## Tài khoản demo

| Vai trò | Tài khoản | Mật khẩu |
|---|---|---|
| Quản trị | `admin` | `123456` |
| Giảng viên | `teacher` | `123456` |
| Học viên | `student` | `123456` |

## Route chính

- `/login`
- `/lms/dashboard`, `/lms/courses`, `/lms/courses/1/lessons/104`
- `/cms/dashboard`, `/cms/courses`, `/cms/videos/101/editor`, `/cms/questions`, `/cms/students`, `/cms/reports`

Thông tin kiến trúc và tích hợp nằm trong thư mục `docs/`.
