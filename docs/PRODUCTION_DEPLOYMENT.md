# Quy trình production LMS/CMS

## Kiến trúc

- Frontend Vue/Vite: `https://lms.newletter.id.vn` trên Vercel project `cms-vue-vercel`.
- Backend ASP.NET Core: `https://app02ngtronggm-001-site1.ltempurl.com` trên SmarterASP.NET.
- SQL Server: database `db_acd794_lms` trên SmarterASP.NET.
- Media production: `wwwroot/Media`; đây là dữ liệu bền vững, không nằm trong package backend.

## Thứ tự release

Chạy từ PowerShell tại project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\production\Build-Frontend.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\production\Publish-Backend.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\production\Invoke-ProductionDatabaseSync.ps1
```

Sau đó:

1. Upload nội dung `artifacts/production/backend/` lên application backend.
2. Không bật chế độ xóa file đích hoặc mirror.
3. Không xóa/ghi đè `wwwroot/Media`.
4. Khởi động lại application pool và kiểm tra `/health`.
5. Deploy frontend:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\production\Deploy-Frontend.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\production\Test-Production.ps1
```

## SQL

Master migration: `database/production/PRODUCTION_SYNC_20260821.sql`.

- Không drop database/table.
- Không truncate/delete dữ liệu nghiệp vụ.
- Không chạy demo seed.
- Ghi audit số dòng từng bảng trước khi migration tại `artifacts/production/sql/pre-deploy-audit.txt`.
- Stored procedure được đồng bộ bằng `Create Or Alter Procedure`.

Rollback schema tự động không được sử dụng vì có thể nguy hiểm hơn thay đổi bổ sung. Nếu stored procedure cần rollback, deploy lại file từ commit production trước đó. Audit trước deploy dùng để đối chiếu dữ liệu, không phải bản backup đầy đủ.

## Secrets

Không commit connection string, JWT key, FTP password hoặc Vercel token. Cấu hình production cục bộ nằm trong file bị Git ignore hoặc biến môi trường của hosting.

## Media

`LmsCms.Api.csproj` loại `wwwroot/Media/**/*` khỏi publish. Backend tự tạo các thư mục Media còn thiếu khi khởi động, nhưng không thay thế file người dùng đã upload.
