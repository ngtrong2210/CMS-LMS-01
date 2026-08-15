import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/authStore'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: () => import('../views/auth/LoginView.vue'), meta: { guest: true } },
  { path: '/lms', component: () => import('../layouts/LmsLayout.vue'), meta: { auth: true, role: 'STUDENT' }, children: [
    { path: '', redirect: '/lms/dashboard' },
    { path: 'dashboard', component: () => import('../views/lms/LmsDashboardView.vue'), meta: { title: 'Tổng quan' } },
    { path: 'courses', component: () => import('../views/lms/CourseListView.vue'), meta: { title: 'Khóa học của tôi' } },
    { path: 'courses/:courseId', component: () => import('../views/lms/CourseDetailView.vue'), meta: { title: 'Chi tiết khóa học' } },
    { path: 'courses/:courseId/lessons/:lessonId', component: () => import('../views/lms/LessonPlayerView.vue'), meta: { title: 'Bài học' } },
    { path: 'results', component: () => import('../views/lms/ResultsView.vue'), meta: { title: 'Kết quả học tập', icon: 'bi-award' } },
    { path: 'profile', component: () => import('../views/lms/SimpleLmsView.vue'), meta: { title: 'Hồ sơ cá nhân', icon: 'bi-person' } },
  ]},
  { path: '/cms', component: () => import('../layouts/CmsLayout.vue'), meta: { auth: true, cms: true }, children: [
    { path: '', redirect: '/cms/dashboard' },
    { path: 'dashboard', component: () => import('../views/cms/CmsDashboardView.vue'), meta: { title: 'Tổng quan' } },
    { path: 'search', component: () => import('../views/cms/GlobalSearchView.vue'), meta: { title: 'Tìm kiếm' } },
    { path: 'courses', component: () => import('../views/cms/CourseManagementView.vue'), meta: { title: 'Khóa học' } },
    { path: 'courses/:id/content', component: () => import('../views/cms/ContentBuilderView.vue'), meta: { title: 'Nội dung khóa học' } },
    { path: 'videos', component: () => import('../views/cms/VideoLibraryView.vue'), meta: { title: 'Thư viện video' } },
    { path: 'videos/:id/editor', component: () => import('../views/cms/VideoEditorView.vue'), meta: { title: 'Biên tập video' } },
    { path: 'questions', component: () => import('../views/cms/QuestionBankView.vue'), meta: { title: 'Ngân hàng câu hỏi' } },
    { path: 'students', component: () => import('../views/cms/StudentsView.vue'), meta: { title: 'Học viên' } },
    { path: 'enrollments', component: () => import('../views/cms/EnrollmentManagementView.vue'), meta: { title: 'Ghi danh khóa học' } },
    { path: 'reports', component: () => import('../views/cms/ReportsView.vue'), meta: { title: 'Báo cáo' } },
    { path: ':section', component: () => import('../views/cms/GenericCmsView.vue') },
  ]},
  { path: '/403', component: () => import('../views/errors/ErrorView.vue'), props: { code: '403', title: 'Bạn không có quyền truy cập' } },
  { path: '/:pathMatch(.*)*', component: () => import('../views/errors/ErrorView.vue'), props: { code: '404', title: 'Không tìm thấy trang' } },
]

const router = createRouter({ history: createWebHistory(), routes, scrollBehavior: () => ({ top: 0 }) })
router.beforeEach(to => {
  const auth = useAuthStore()
  if (to.meta.auth && !auth.isAuthenticated) return '/login'
  if (to.meta.role === 'STUDENT' && !auth.isStudent) return '/403'
  if (to.meta.cms && !auth.isCmsUser) return '/403'
  if (to.meta.guest && auth.isAuthenticated) return auth.isStudent ? '/lms/dashboard' : '/cms/dashboard'
})
export default router
