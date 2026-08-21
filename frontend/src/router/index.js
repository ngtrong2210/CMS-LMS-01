import { createRouter, createWebHistory } from 'vue-router'
import axiosClient from '../api/axiosClient'
import { useAuthStore } from '../stores/authStore'

const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)

async function redirectCourseToCurrentLesson(to) {
  const courseId = Number(to.params.courseId)
  if (!courseId) return { path: '/lms/courses', replace: true }

  try {
    const courseRows = await axiosClient.get('/lms/courses', { params: { _fresh: Date.now() } })
    const course = (Array.isArray(courseRows) ? courseRows : []).find(
      (row) => Number(pick(row, 'Id', 'id')) === courseId
    )
    let lessonId = Number(pick(course, 'ContinueLessonId', 'continueLessonId') || 0)

    if (!lessonId) {
      const detail = await axiosClient.get(`/lms/courses/${courseId}`, { params: { _fresh: Date.now() } })
      const lessons = pick(detail, 'lessons', 'Lessons') || []
      const currentLesson = lessons.find((lesson) => !Boolean(pick(lesson, 'Completed', 'completed'))) || lessons[0]
      lessonId = Number(pick(currentLesson, 'Id', 'id') || 0)
    }

    return lessonId
      ? { path: `/lms/courses/${courseId}/lessons/${lessonId}`, replace: true }
      : { path: '/lms/courses', replace: true }
  } catch {
    return { path: '/lms/courses', replace: true }
  }
}

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: () => import('../views/auth/LoginView.vue'), meta: { guest: true, hideBack: true } },
  {
    path: '/lms',
    component: () => import('../layouts/LmsLayout.vue'),
    meta: { auth: true, role: 'STUDENT' },
    children: [
      { path: '', redirect: '/lms/dashboard' },
      {
        path: 'dashboard',
        component: () => import('../views/lms/LmsDashboardView.vue'),
        meta: { title: 'Tổng quan', hideBack: true }
      },
      {
        path: 'courses',
        component: () => import('../views/lms/CourseListView.vue'),
        meta: { title: 'Môn học của tôi' }
      },
      {
        path: 'courses/:courseId',
        component: () => import('../views/lms/CourseListView.vue'),
        beforeEnter: redirectCourseToCurrentLesson,
        meta: { title: 'Mở môn học', backTo: '/lms/courses' }
      },
      {
        path: 'courses/:courseId/lessons/:lessonId',
        component: () => import('../views/lms/LessonPlayerView.vue'),
        meta: {
          title: 'Bài học',
          backTo: '/lms/courses',
          hideBack: true,
          fullWidth: true,
          immersive: true
        }
      },
      {
        path: 'results',
        component: () => import('../views/lms/ResultsView.vue'),
        meta: { title: 'Kết quả học tập', icon: 'bi-award' }
      },
      {
        path: 'profile',
        component: () => import('../views/lms/SimpleLmsView.vue'),
        meta: { title: 'Hồ sơ cá nhân', icon: 'bi-person' }
      }
    ]
  },
  {
    path: '/cms',
    component: () => import('../layouts/CmsLayout.vue'),
    meta: { auth: true, cms: true },
    children: [
      { path: '', redirect: '/cms/dashboard' },
      {
        path: 'dashboard',
        component: () => import('../views/cms/CmsDashboardView.vue'),
        meta: { title: 'Tổng quan', hideBack: true }
      },
      { path: 'search', component: () => import('../views/cms/GlobalSearchView.vue'), meta: { title: 'Tìm kiếm' } },
      {
        path: 'academic',
        component: () => import('../views/cms/AcademicStructureView.vue'),
        meta: { title: 'Cơ cấu đào tạo' }
      },
      {
        path: 'courses',
        name: 'CourseManagementView',
        component: () => import('../views/cms/CourseManagementView.vue'),
        meta: { title: 'Soạn môn học lớp' }
      },
      {
        path: 'courses/:id/content',
        component: () => import('../views/cms/ContentBuilderView.vue'),
        meta: { title: 'Soạn chương và bài', backTo: '/cms/courses' }
      },
      {
        path: 'assignments',
        name: 'AssignmentGradingView',
        component: () => import('../views/cms/AssignmentGradingView.vue'),
        meta: { title: 'Chấm và trả bài' }
      },
      {
        path: 'videos',
        component: () => import('../views/cms/VideoLibraryView.vue'),
        meta: { title: 'Thư viện video' }
      },
      {
        path: 'videos/:id/editor',
        component: () => import('../views/cms/VideoEditorView.vue'),
        meta: { title: 'Biên tập video', backTo: '/cms/videos' }
      },
      {
        path: 'questions',
        component: () => import('../views/cms/QuestionBankView.vue'),
        meta: { title: 'Ngân hàng câu hỏi' }
      },
      { path: 'students', component: () => import('../views/cms/StudentsView.vue'), meta: { title: 'Học viên' } },
      {
        path: 'enrollments',
        redirect: '/cms/academic'
      },
      { path: 'reports', component: () => import('../views/cms/ReportsView.vue'), meta: { title: 'Báo cáo' } },
      {
        path: 'users',
        name: 'UsersManagementView',
        component: () => import('../views/cms/UsersManagementView.vue'),
        meta: { title: 'Người dùng', admin: true }
      },
      {
        path: 'roles',
        name: 'RoleManagementView',
        component: () => import('../views/cms/RoleManagementView.vue'),
        meta: { title: 'Phân quyền', admin: true }
      },
      {
        path: 'settings',
        name: 'SystemSettingsView',
        component: () => import('../views/cms/SystemSettingsView.vue'),
        meta: { title: 'Cài đặt', admin: true }
      },
      { path: ':section', component: () => import('../views/cms/GenericCmsView.vue') }
    ]
  },
  {
    path: '/403',
    component: () => import('../views/errors/ErrorView.vue'),
    props: { code: '403', title: 'Bạn không có quyền truy cập' }
  },
  {
    path: '/:pathMatch(.*)*',
    component: () => import('../views/errors/ErrorView.vue'),
    props: { code: '404', title: 'Không tìm thấy trang' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: (to, from, savedPosition) => savedPosition || { top: 0 }
})
router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.auth && !auth.isAuthenticated) return '/login'
  if (to.meta.role === 'STUDENT' && !auth.isStudent) return '/403'
  if (to.meta.cms && !auth.isCmsUser) return '/403'
  if (to.meta.admin && !auth.isAdmin) return '/403'
  if (to.meta.guest && auth.isAuthenticated) return auth.isStudent ? '/lms/dashboard' : '/cms/dashboard'
})
export default router
