const LESSON_TYPE_MAP = Object.freeze({
  VIDEO: { label: 'Video', icon: 'bi-play-fill', tone: 'blue' },
  INTERACTIVE_VIDEO: { label: 'Video tương tác', icon: 'bi-play-fill', tone: 'blue' },
  INTERACTIVE_CONTENT: { label: 'Bài học tương tác', icon: 'bi-journal-check', tone: 'teal' },
  EDITOR: { label: 'Bài học', icon: 'bi-file-text-fill', tone: 'cyan' },
  CONTENT: { label: 'Bài đọc', icon: 'bi-file-text-fill', tone: 'cyan' },
  DOCUMENT: { label: 'Bài học', icon: 'bi-file-text-fill', tone: 'cyan' },
  PDF: { label: 'Tài liệu PDF', icon: 'bi-file-earmark-pdf-fill', tone: 'red' },
  ASSIGNMENT: { label: 'Bài tập', icon: 'bi-clipboard-check-fill', tone: 'orange' },
  QUIZ: { label: 'Bài kiểm tra', icon: 'bi-ui-checks', tone: 'purple' },
  TEST: { label: 'Bài kiểm tra', icon: 'bi-ui-checks', tone: 'purple' },
  PRACTICE: { label: 'Thực hành', icon: 'bi-tools', tone: 'green' },
  FILE: { label: 'Tệp học tập', icon: 'bi-file-earmark-arrow-down-fill', tone: 'slate' },
  LINK: { label: 'Liên kết', icon: 'bi-box-arrow-up-right', tone: 'teal' }
})

const FALLBACK_TYPE = Object.freeze({ label: 'Bài học', icon: 'bi-journal-bookmark-fill', tone: 'slate' })

export function lessonTypeMeta(type) {
  return LESSON_TYPE_MAP[String(type || '').toUpperCase()] || FALLBACK_TYPE
}

export function lessonTypeClass(type) {
  return `lesson-type-${lessonTypeMeta(type).tone}`
}
