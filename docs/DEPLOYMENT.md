# Phiên bản production LMS/CMS

- Git branch: `main`
- Git commit nguồn release: `331001d`
- Deployment date: 2026-08-21 (Asia/Saigon)
- Frontend: `https://lms.newletter.id.vn`
- Vercel project: `cms-vue-vercel`
- Backend: `https://app02ngtronggm-001-site1.ltempurl.com`
- Database: `db_acd794_lms`
- Latest migration: `database/production/PRODUCTION_SYNC_20260821.sql`
- Media policy: giữ nguyên `wwwroot/Media`, không nằm trong backend package

## Kết quả đồng bộ 2026-08-21

- SQL production: đã chạy `PRODUCTION_SYNC_20260821.sql`, kết quả `PRODUCTION_SYNC_COMPLETED`.
- Backend SmarterASP: đã upload và giải nén package mới vào `/lms`; package không chứa `wwwroot/Media`.
- Backend health: `Healthy`; SQL Server health: `Healthy`.
- Frontend production: asset đang phục vụ trùng chính xác với bản build local (`index-D5jOVIRD.js`).
- Vercel CLI: không tạo deployment mới vì tài khoản CLI hiện tại không có quyền với team `2nt1`; không ghi nhận sai thao tác này là đã chạy.
- Git: commit nguồn release `331001d` đã push lên `origin/main`.
- Public smoke test: `/`, `/login`, `/cms/dashboard`, `/lms/courses` và backend `/health` đều HTTP 200.
- API smoke test: đăng nhập và các luồng đọc chính của ADMIN, TEACHER, STUDENT đều thành công.
- Media smoke test: file mẫu `/Media/Video/demo/z5.mp4` còn tồn tại và trả HTTP 200 sau deploy.

Quy trình chi tiết: `docs/PRODUCTION_DEPLOYMENT.md`.
