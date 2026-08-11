# Mock Data

Mock data nằm trong `frontend/src/mock` và được nạp vào localStorage với key `learnhub_mock_database_v1`.

`MockDatabaseService` hỗ trợ initialize, reset, get, find, insert, update và delete. ID giữa user, course, chapter, lesson, video, question, interaction, enrollment và progress tương thích với mô hình SQL.

Xóa key localStorage hoặc gọi `reset()` để phục hồi dữ liệu demo.
