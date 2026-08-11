# Frontend Architecture

Frontend dùng Vue 3 Composition API, Vue Router, Pinia, Axios và Bootstrap 5. Các route được lazy-load và bảo vệ theo vai trò.

Luồng dữ liệu chuẩn: `View → Store/Service → Repository → Mock storage hoặc API`.

- `src/api`: cấu hình Axios, token interceptor, chuẩn hóa lỗi.
- `src/repositories`: contract triển khai theo mock/API.
- `src/services`: chọn repository từ `VITE_DATA_MODE`.
- `src/stores`: trạng thái phiên đăng nhập và dữ liệu dùng chung.
- `src/layouts`: layout riêng cho LMS và CMS.
- `src/views`: màn hình nghiệp vụ.
- `src/mock`: dữ liệu seed có quan hệ ID tương thích SQL.

Theme sáng dùng `#07875a`, `#005099`, `#cd1b1b`, `#ffff1a`. Màu thương hiệu dùng cho action, trạng thái và mảng nhấn; đường phân tách dùng màu xám trung tính.
