<template>
  <div class="lms-shell">
    <div v-if="!route.meta.immersive" class="learning-strip">
      <div class="container">
        <span><i class="bi bi-mortarboard"></i> Hệ thống học tập trực tuyến LearnHub</span
        ><span class="d-none d-md-inline"><i class="bi bi-headset"></i> Hỗ trợ học viên: Bộ phận đào tạo</span>
      </div>
    </div>
    <nav v-if="!route.meta.immersive" class="navbar navbar-expand-lg sticky-top lms-nav">
      <div class="container py-2">
        <RouterLink class="brand" to="/lms/dashboard"
          ><img class="eduvers-logo" src="/images/eduvers/logo-1.png" alt="Eduvers"
        /></RouterLink>
        <button class="navbar-toggler border-0" data-bs-toggle="collapse" data-bs-target="#lmsNav">
          <i class="bi bi-list fs-2"></i>
        </button>
        <div id="lmsNav" class="collapse navbar-collapse">
          <div class="navbar-nav mx-auto gap-lg-2">
            <RouterLink class="nav-link" to="/lms/dashboard">Tổng quan</RouterLink>
            <RouterLink class="nav-link" to="/lms/courses">Môn học của tôi</RouterLink>
            <RouterLink class="nav-link" to="/lms/results">Kết quả</RouterLink>
          </div>
          <div class="d-flex align-items-center gap-2 mt-3 mt-lg-0">
            <NotificationCenter />
            <RouterLink to="/lms/profile" class="profile-link d-flex align-items-center gap-2"
              ><img
                class="avatar user-avatar"
                :src="avatarUrl"
                :alt="`Ảnh đại diện ${auth.user?.fullName || ''}`"
              /><span class="profile-copy d-none d-xl-grid"
                ><strong>{{ auth.user?.fullName }}</strong
                ><small>Học viên</small></span
              ></RouterLink
            >
            <button class="btn btn-action-delete btn-sm" title="Đăng xuất" @click="signOut">
              <i class="bi bi-box-arrow-right"></i>
            </button>
          </div>
        </div>
      </div>
    </nav>
    <main
      :class="[
        'lms-content',
        route.meta.immersive
          ? 'container-fluid full-width immersive p-0'
          : route.meta.fullWidth
            ? 'container-fluid full-width px-2 px-lg-3 py-3'
            : 'container py-4 py-lg-5'
      ]"
    >
      <div v-if="!route.meta.hideBack" class="lms-back-row"><PageBackButton /></div>
      <RouterView v-slot="{ Component }">
        <KeepAlive :include="cachedPages" :max="6">
          <component :is="Component" />
        </KeepAlive>
      </RouterView>
    </main>
    <footer v-if="!route.meta.immersive" class="lms-footer">
      <div class="container">
        <span>© 2026 LearnHub · Hệ thống quản lý học tập</span><span>Hỗ trợ · Quy định học tập · Bảo mật</span>
      </div>
    </footer>
  </div>
</template>
<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import NotificationCenter from '../components/feedback/NotificationCenter.vue'
import { useAuthStore } from '../stores/authStore'
import PageBackButton from '../components/navigation/PageBackButton.vue'
const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const cachedPages = ['CourseListView', 'CourseDetailView', 'ResultsView', 'SimpleLmsView']
const avatarUrl = computed(
  () =>
    ({
      ADMIN: '/images/avatar-admin.jpg',
      TEACHER: '/images/avatar-teacher.jpg',
      STUDENT: '/images/avatar-student.jpg'
    })[auth.user?.role] || '/images/avatar-student.jpg'
)
function signOut() {
  auth.logout()
  router.push('/login')
}
</script>
<style scoped src="../assets/css/layouts/lms-layout.css"></style>
