<template>
  <div :class="['cms-shell', 'cms-theme', { 'sidebar-collapsed': sidebarCollapsed }]">
    <aside class="sidebar d-none d-lg-flex flex-column">
      <RouterLink class="brand px-4" to="/cms/dashboard"
        ><img class="eduvers-logo" src="/images/eduvers/logo-1.png" alt="Eduvers"
      /></RouterLink>
      <nav :class="['px-3', 'overflow-auto', { scrolling: sidebarScrolling }]" @scroll="showSidebarScrollbar">
        <template v-for="group in menu" :key="group.label">
          <div class="menu-label">{{ group.label }}</div>
          <RouterLink
            v-for="item in group.items"
            :key="item.to"
            class="side-link"
            :to="item.to"
            :title="sidebarCollapsed ? item.text : undefined"
            :aria-label="sidebarCollapsed ? item.text : undefined"
            ><i :class="['bi', item.icon]"></i><span>{{ item.text }}</span></RouterLink
          >
        </template>
      </nav>
    </aside>
    <div class="cms-main">
      <header class="topbar d-flex align-items-center justify-content-between px-3 px-lg-4">
        <div class="topbar-heading d-flex align-items-center gap-3">
          <button
            class="btn btn-light d-lg-none menu-toggle"
            data-bs-toggle="offcanvas"
            data-bs-target="#mobileMenu"
            aria-label="Mở trình đơn"
          >
            <i class="bi bi-list"></i></button
          ><button
            type="button"
            class="sidebar-toggle d-none d-lg-grid"
            :aria-label="sidebarCollapsed ? 'Mở rộng thanh menu' : 'Thu gọn thanh menu'"
            :title="sidebarCollapsed ? 'Mở rộng menu' : 'Thu gọn menu'"
            @click="toggleSidebar"
          >
            <svg class="sidebar-toggle-icon" viewBox="0 0 24 24" aria-hidden="true">
              <rect x="2.75" y="3.25" width="18.5" height="17.5" rx="3"></rect>
              <path d="M8.25 3.5v17"></path>
              <path v-if="sidebarCollapsed" d="m12 8 4 4-4 4"></path>
              <path v-else d="m16 8-4 4 4 4"></path>
            </svg>
          </button>
          <div>
            <small>ELEARNING</small>
            <div>{{ route.meta.title || sectionTitle }}</div>
          </div>
        </div>
        <div class="topbar-actions d-flex align-items-center gap-2 gap-lg-3">
          <form class="top-search d-none d-xl-flex" role="search" @submit.prevent="submitGlobalSearch">
            <i class="bi bi-search"></i
            ><input
              v-model="globalSearch"
              type="search"
              aria-label="Tìm kiếm"
              placeholder="Tìm kiếm trong hệ thống..."
              autocomplete="off"
            /><button type="submit" aria-label="Mở kết quả tìm kiếm"><i class="bi bi-arrow-right"></i></button>
          </form>
          <RouterLink class="icon-button d-xl-none" to="/cms/search" aria-label="Tìm kiếm"
            ><i class="bi bi-search"></i></RouterLink
          ><button class="icon-button" aria-label="Thông báo"><i class="bi bi-bell"></i><span></span></button>
          <div class="d-none d-sm-flex align-items-center gap-2 user-summary">
            <img class="avatar user-avatar" :src="avatarUrl" :alt="`Ảnh đại diện ${auth.user?.fullName || ''}`" />
            <div>
              <div class="small fw-bold">{{ auth.user?.fullName }}</div>
              <div class="tiny">{{ roleName }}</div>
            </div>
          </div>
          <button class="btn btn-light btn-sm logout-button" title="Đăng xuất" @click="signOut">
            <i class="bi bi-box-arrow-right"></i>
          </button>
        </div>
      </header>
      <main class="p-3 p-lg-4 page-content">
        <div v-if="!route.meta.hideBack" class="cms-back-row"><PageBackButton /></div>
        <RouterView v-slot="{ Component }">
          <KeepAlive :include="cachedPages" :max="12">
            <component :is="Component" />
          </KeepAlive>
        </RouterView>
      </main>
    </div>
    <div id="mobileMenu" class="offcanvas offcanvas-start mobile-sidebar">
      <div class="offcanvas-header">
        <RouterLink class="brand" to="/cms/dashboard" data-bs-dismiss="offcanvas"
          ><img class="eduvers-logo" src="/images/eduvers/logo-1.png" alt="Eduvers" /></RouterLink
        ><button class="btn-close" data-bs-dismiss="offcanvas" aria-label="Đóng"></button>
      </div>
      <div class="offcanvas-body">
        <template v-for="group in menu" :key="group.label"
          ><div class="menu-label">{{ group.label }}</div>
          <RouterLink
            v-for="item in group.items"
            :key="item.to"
            class="side-link"
            :to="item.to"
            data-bs-dismiss="offcanvas"
            ><i :class="['bi', item.icon]"></i>{{ item.text }}</RouterLink
          ></template
        >
      </div>
    </div>
  </div>
</template>
<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/authStore'
import PageBackButton from '../components/navigation/PageBackButton.vue'
const route = useRoute(),
  router = useRouter(),
  auth = useAuthStore()
const sectionTitle = computed(() => route.params.section || 'Quản trị')
const sidebarCollapsed = ref(localStorage.getItem('cms_sidebar_collapsed') === '1')
const sidebarScrolling = ref(false)
const globalSearch = ref(String(route.query.q || ''))
const cachedPages = [
  'CourseManagementView',
  'VideoLibraryView',
  'QuestionBankView',
  'StudentsView',
  'EnrollmentManagementView',
  'ReportsView',
  'GlobalSearchView',
  'GenericCmsView'
]
const avatarUrl = computed(
  () =>
    ({
      ADMIN: '/images/avatar-admin.jpg',
      TEACHER: '/images/avatar-teacher.jpg',
      STUDENT: '/images/avatar-student.jpg'
    })[auth.user?.role] || '/images/avatar-admin.jpg'
)
const roleName = computed(() => ({ ADMIN: 'Quản trị viên', TEACHER: 'Giảng viên' })[auth.user?.role] || auth.user?.role)
const menu = [
  { label: 'Tổng quan', items: [{ to: '/cms/dashboard', text: 'Bảng điều khiển', icon: 'bi-grid' }] },
  {
    label: 'Đào tạo',
    items: [
      { to: '/cms/courses', text: 'Khóa học', icon: 'bi-journal-bookmark' },
      { to: '/cms/videos', text: 'Thư viện video', icon: 'bi-collection-play' },
      { to: '/cms/questions', text: 'Ngân hàng câu hỏi', icon: 'bi-patch-question' }
    ]
  },
  {
    label: 'Học viên',
    items: [
      { to: '/cms/students', text: 'Danh sách học viên', icon: 'bi-people' },
      { to: '/cms/enrollments', text: 'Ghi danh khóa học', icon: 'bi-person-plus' }
    ]
  },
  { label: 'Phân tích', items: [{ to: '/cms/reports', text: 'Báo cáo', icon: 'bi-bar-chart' }] },
  {
    label: 'Hệ thống',
    items: [
      { to: '/cms/users', text: 'Người dùng', icon: 'bi-person-gear' },
      { to: '/cms/roles', text: 'Phân quyền', icon: 'bi-shield-check' },
      { to: '/cms/settings', text: 'Cài đặt', icon: 'bi-gear' }
    ]
  }
]
function signOut() {
  auth.logout()
  router.push('/login')
}
function submitGlobalSearch() {
  const term = globalSearch.value.trim()
  router.push(term ? { path: '/cms/search', query: { q: term } } : { path: '/cms/search' })
}
function toggleSidebar() {
  sidebarCollapsed.value = !sidebarCollapsed.value
  localStorage.setItem('cms_sidebar_collapsed', sidebarCollapsed.value ? '1' : '0')
}
let sidebarScrollTimer
function showSidebarScrollbar() {
  sidebarScrolling.value = true
  clearTimeout(sidebarScrollTimer)
  sidebarScrollTimer = setTimeout(() => (sidebarScrolling.value = false), 650)
}
onBeforeUnmount(() => clearTimeout(sidebarScrollTimer))
watch(
  () => route.query.q,
  (value) => (globalSearch.value = String(value || ''))
)
</script>
<style scoped src="../assets/css/layouts/cms-layout.css"></style>
