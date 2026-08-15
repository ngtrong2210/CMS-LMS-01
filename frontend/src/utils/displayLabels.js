const STATUS_LABELS = Object.freeze({
  ACTIVE: 'Hoạt động',
  INACTIVE: 'Tạm ẩn',
  PUBLISHED: 'Đã xuất bản',
  DRAFT: 'Bản nháp',
  ARCHIVED: 'Đã lưu trữ',
  LOCKED: 'Đã khóa',
  ENROLLED: 'Đã ghi danh',
  IN_PROGRESS: 'Đang học',
  COMPLETED: 'Hoàn thành',
  CANCELLED: 'Đã hủy'
})

const QUESTION_TYPE_LABELS = Object.freeze({
  SINGLE_CHOICE: 'Một lựa chọn',
  MULTIPLE_CHOICE: 'Nhiều lựa chọn',
  TRUE_FALSE: 'Đúng / Sai',
  SHORT_ANSWER: 'Trả lời ngắn'
})

export function statusLabel(value, fallback = 'Sẵn sàng') {
  return STATUS_LABELS[value] || value || fallback
}

export function questionTypeLabel(value, fallback = 'Chưa xác định') {
  return QUESTION_TYPE_LABELS[value] || value || fallback
}

export function courseStatusBadgeClass(value) {
  return (
    {
      PUBLISHED: 'badge-soft-success',
      DRAFT: 'badge-soft-warning',
      ARCHIVED: 'badge-soft-primary'
    }[value] || 'badge-soft-primary'
  )
}
