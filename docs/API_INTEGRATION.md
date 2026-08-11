# API Integration

API trả về cấu trúc:

```json
{ "success": true, "message": "", "data": {}, "errors": [] }
```

`axiosClient` tự thêm Bearer token và chuyển lỗi HTTP thành lỗi thống nhất. Component không gọi Axios trực tiếp.

Các endpoint lõi đã kết nối contract:

- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/courses`
- `GET /api/courses/{id}`
- `GET /api/courses/{id}/content`
- `GET /api/lms/lessons/{lessonId}/player`
- `POST /api/lms/progress/video`
- `POST /api/lms/answers`
- `GET /api/cms/dashboard`

Để chuyển sang API mode, đặt `VITE_DATA_MODE=api` và `VITE_API_URL=https://localhost:7001/api`.
