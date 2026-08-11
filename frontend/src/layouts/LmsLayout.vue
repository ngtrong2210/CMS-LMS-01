<template>
  <div class="lms-shell">
    <nav class="navbar navbar-expand-lg bg-white sticky-top lms-nav">
      <div class="container py-2">
        <RouterLink class="brand" to="/lms/dashboard"><img class="brand-mark" src="/images/learnhub-mark.svg" alt=""><span>LearnHub</span></RouterLink>
        <button class="navbar-toggler border-0" data-bs-toggle="collapse" data-bs-target="#lmsNav"><i class="bi bi-list fs-2"></i></button>
        <div id="lmsNav" class="collapse navbar-collapse">
          <div class="navbar-nav mx-auto gap-lg-2">
            <RouterLink class="nav-link" to="/lms/dashboard">Tổng quan</RouterLink>
            <RouterLink class="nav-link" to="/lms/courses">Khóa học của tôi</RouterLink>
            <RouterLink class="nav-link" to="/lms/results">Kết quả</RouterLink>
          </div>
          <div class="d-flex align-items-center gap-2 mt-3 mt-lg-0">
            <RouterLink to="/lms/profile" class="profile-link d-flex align-items-center gap-2"><img class="avatar user-avatar" :src="avatarUrl" :alt="`Ảnh đại diện ${auth.user?.fullName || ''}`"><span class="small fw-semibold d-none d-xl-inline">{{ auth.user?.fullName }}</span></RouterLink>
            <button class="btn btn-light btn-sm" title="Đăng xuất" @click="signOut"><i class="bi bi-box-arrow-right"></i></button>
          </div>
        </div>
      </div>
    </nav>
    <main class="container py-4 py-lg-5 lms-content"><RouterView /></main>
  </div>
</template>
<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/authStore'
const auth = useAuthStore(); const router = useRouter()
const avatarUrl=computed(()=>({ADMIN:'/images/avatar-admin.jpg',TEACHER:'/images/avatar-teacher.jpg',STUDENT:'/images/avatar-student.jpg'})[auth.user?.role] || '/images/avatar-student.jpg')
function signOut() { auth.logout(); router.push('/login') }
</script>
<style scoped>
.lms-nav { box-shadow:0 3px 18px rgba(21,47,39,.055); }
.brand { display:flex; align-items:center; gap:.65rem; font-size:1.2rem; font-weight:850; }
.brand-mark { width:38px; height:38px; border-radius:10px; display:block; object-fit:contain; box-shadow:0 5px 15px rgba(7,135,90,.18) }
.nav-link { border-radius:7px; padding:.55rem .85rem !important; font-weight:650; color:#60716b; }
.nav-link.router-link-active { color:#07875a; background:#e9f6f1; }
.profile-link{padding:.25rem .5rem;border-radius:8px}.profile-link:hover{background:#f3f7f5}.user-avatar{display:block;object-fit:cover;border:2px solid #fff;box-shadow:0 2px 9px rgba(18,54,43,.14)}.lms-content{max-width:1320px}
</style>
