import { describe, expect, it } from 'vitest'
import { lessonTypeClass, lessonTypeMeta } from './lessonTypes'

describe('lessonTypes', () => {
  it('dùng chung màu và icon cho video tương tác', () => {
    expect(lessonTypeMeta('INTERACTIVE_VIDEO')).toEqual({
      label: 'Video tương tác',
      icon: 'bi-play-fill',
      tone: 'blue'
    })
    expect(lessonTypeClass('INTERACTIVE_VIDEO')).toBe('lesson-type-blue')
  })

  it('phân biệt bài tập, tài liệu và bài kiểm tra', () => {
    expect(lessonTypeClass('ASSIGNMENT')).toBe('lesson-type-orange')
    expect(lessonTypeClass('DOCUMENT')).toBe('lesson-type-red')
    expect(lessonTypeClass('QUIZ')).toBe('lesson-type-purple')
  })

  it('hiển thị đúng bài học đọc hiểu tương tác', () => {
    expect(lessonTypeMeta('INTERACTIVE_CONTENT')).toEqual({
      label: 'Bài học tương tác',
      icon: 'bi-journal-check',
      tone: 'teal'
    })
    expect(lessonTypeClass('INTERACTIVE_CONTENT')).toBe('lesson-type-teal')
  })

  it('trả về kiểu dự phòng an toàn cho dữ liệu lạ', () => {
    expect(lessonTypeMeta('UNKNOWN')).toEqual({
      label: 'Bài học',
      icon: 'bi-journal-bookmark-fill',
      tone: 'slate'
    })
  })
})
