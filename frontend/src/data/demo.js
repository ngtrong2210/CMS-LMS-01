export const demoUsers = [
  { id: 1, username: 'admin', password: '123456', fullName: 'Quản trị hệ thống', email: 'admin@learnhub.vn', role: 'ADMIN', permissions: ['*'] },
  { id: 2, username: 'teacher', password: '123456', fullName: 'Nguyễn Văn Giảng', email: 'teacher@learnhub.vn', role: 'TEACHER', permissions: ['DASHBOARD_VIEW','COURSE_VIEW','COURSE_EDIT','CHAPTER_CREATE','CHAPTER_EDIT','LESSON_CREATE','LESSON_EDIT','VIDEO_VIEW','VIDEO_EDIT','VIDEO_INTERACTION_EDIT','QUESTION_VIEW','QUESTION_CREATE','QUESTION_EDIT','STUDENT_VIEW','REPORT_VIEW'] },
  { id: 3, username: 'student', password: '123456', fullName: 'Nguyễn Văn Học', email: 'student@learnhub.vn', studentCode: 'HV0001', role: 'STUDENT', permissions: [] },
]
export const courses = [
  { id: 1, code: 'VUE3-001', title: 'Vue.js 3 từ cơ bản đến nâng cao', teacher: 'Nguyễn Văn Giảng', category: 'Lập trình Frontend', level: 'Cơ bản đến nâng cao', lessons: 15, students: 128, progress: 42, score: 8.4, status: 'PUBLISHED', lastLesson: 'Computed và Watch', color: '#07875a' },
  { id: 2, code: 'UIUX-002', title: 'Nền tảng thiết kế giao diện số', teacher: 'Trần Minh Anh', category: 'Thiết kế', level: 'Cơ bản', lessons: 12, students: 76, progress: 68, score: 8.8, status: 'PUBLISHED', lastLesson: 'Hệ thống màu sắc', color: '#005099' },
  { id: 3, code: 'API-003', title: 'Thiết kế REST API thực chiến', teacher: 'Lê Quốc Bảo', category: 'Backend', level: 'Trung cấp', lessons: 18, students: 95, progress: 18, score: 7.5, status: 'DRAFT', lastLesson: 'HTTP Methods', color: '#cd1b1b' },
]
export const chapters = [
  { id: 1, title: 'Tổng quan Vue.js', lessons: [
    { id: 101, title: 'Vue.js là gì?', duration: '08:20', completed: true }, { id: 102, title: 'Cài đặt môi trường', duration: '12:10', completed: true }, { id: 103, title: 'Template Syntax', duration: '16:45', completed: true }, { id: 104, title: 'Computed và Watch', duration: '18:30', current: true }]},
  { id: 2, title: 'Component', lessons: [
    { id: 201, title: 'Component cơ bản', duration: '14:00' }, { id: 202, title: 'Props và Emits', duration: '20:15' }, { id: 203, title: 'Slots', duration: '13:40' }, { id: 204, title: 'Lifecycle Hooks', duration: '17:25' }]},
  { id: 3, title: 'Vue Router', lessons: [
    { id: 301, title: 'Routing cơ bản', duration: '19:00' }, { id: 302, title: 'Navigation Guards', duration: '16:20' }, { id: 303, title: 'Lazy Loading', duration: '11:40' }]},
  { id: 4, title: 'Pinia và quản lý trạng thái', lessons: [
    { id: 401, title: 'Khởi tạo Store', duration: '18:10' }, { id: 402, title: 'Actions và Getters', duration: '21:05' }, { id: 403, title: 'Persist State', duration: '15:30' }, { id: 404, title: 'Dự án tổng kết', duration: '28:00' }]},
]
export const interactions = [
  { id: 1, time: 20, label: 'Vue.js là gì?', type: 'SINGLE_CHOICE', answered: true, correct: true },
  { id: 2, time: 65, label: 'Composition API dùng để làm gì?', type: 'MULTIPLE_CHOICE', answered: false },
  { id: 3, time: 150, label: 'Vue là một framework backend?', type: 'TRUE_FALSE', answered: false },
]
export const students = [
  { id: 3, code: 'HV0001', name: 'Nguyễn Văn Học', email: 'student@learnhub.vn', courses: 3, progress: 42, score: 8.4, status: 'Đang học' },
  { id: 4, code: 'HV0002', name: 'Trần Thu Hà', email: 'ha.tran@example.vn', courses: 2, progress: 76, score: 9.1, status: 'Đang học' },
  { id: 5, code: 'HV0003', name: 'Phạm Minh Khang', email: 'khang.pham@example.vn', courses: 4, progress: 55, score: 7.8, status: 'Đang học' },
  { id: 6, code: 'HV0004', name: 'Lê Hoàng Nam', email: 'nam.le@example.vn', courses: 1, progress: 100, score: 8.7, status: 'Hoàn thành' },
]
