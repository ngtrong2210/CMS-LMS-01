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
- Ghi audit số dòng từng bảng trước và sau migration tại `artifacts/production/sql/pre-deploy-audit.json` và `post-deploy-audit.json`.
- Dừng release nếu phát hiện số dòng của bất kỳ bảng hiện hữu nào bị giảm.
- Stored procedure được đồng bộ bằng `Create Or Alter Procedure`.

Rollback schema tự động không được sử dụng vì có thể nguy hiểm hơn thay đổi bổ sung. Nếu stored procedure cần rollback, deploy lại file từ commit production trước đó. Audit trước deploy dùng để đối chiếu dữ liệu, không phải bản backup đầy đủ.

## Secrets

Không commit connection string, JWT key, FTP password hoặc Vercel token. Cấu hình production cục bộ nằm trong file bị Git ignore hoặc biến môi trường của hosting.

## Media

`Sims.Api.csproj` loại `wwwroot/Media/**/*` khỏi publish. Backend tự tạo các thư mục Media còn thiếu khi khởi động, nhưng không thay thế file người dùng đã upload.

## Xác minh release 2026-08-21

- Commit nguồn: `331001d` trên nhánh `main`.
- SQL master hoàn tất với marker `PRODUCTION_SYNC_COMPLETED`.
- Audit idempotent tại commit `fbeacaf`: trước/sau đều có `49` bảng, `123` procedure; không có bảng giảm số dòng.
- Backend package được giải nén thành công trên SmarterASP.NET và không chứa thư mục Media.
- Health check backend và SQL Server đều `Healthy`.
- Asset frontend production trùng với bản build local: `index-D5jOVIRD.js`.
- Lệnh Vercel CLI không tạo deployment mới do tài khoản CLI hiện tại không thuộc team `2nt1`. Vì production đã phục vụ đúng cùng artifact, trạng thái được ghi nhận là đồng bộ artifact, không ghi nhận là một Vercel redeploy mới.
