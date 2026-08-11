# Interactive Video Flow

Player theo dõi `previousTime < interaction.time && currentTime >= interaction.time`, sau đó tạm dừng video và mở câu hỏi. Các interaction đã kích hoạt được ghi vào `Set` để tránh mở lặp.

Tiến độ gồm current time, max watched time và watch percent. Frontend gửi autosave theo chu kỳ và ở các sự kiện pause, interaction, submit answer, ended, route leave. Backend clamp dữ liệu theo duration và không cho request cũ làm giảm max watched time.

Student player API không trả `IsCorrect` hoặc answer key. Điểm chính thức luôn do backend tính.
