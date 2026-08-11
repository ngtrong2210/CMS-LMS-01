<template>
  <div class="lms-shell">
    <nav class="navbar navbar-expand-lg bg-white sticky-top lms-nav">
      <div class="container py-2">
        <RouterLink class="brand" to="/lms/dashboard"><span class="brand-mark">L</span><span>LearnHub</span></RouterLink>
        <button class="navbar-toggler border-0" data-bs-toggle="collapse" data-bs-target="#lmsNav"><i class="bi bi-list fs-2"></i></button>
        <div id="lmsNav" class="collapse navbar-collapse">
          <div class="navbar-nav mx-auto gap-lg-2">
            <RouterLink class="nav-link" to="/lms/dashboard">Tổng quan</RouterLink>
            <RouterLink class="nav-link" to="/lms/courses">Khóa học của tôi</RouterLink>
            <RouterLink class="nav-link" to="/lms/results">Kết quả</RouterLink>
          </div>
          <div class="d-flex align-items-center gap-2 mt-3 mt-lg-0">
            <RouterLink to="/lms/profile" class="profile-link d-flex align-items-center gap-2"><span class="avatar">{{ initials }}</span><span class="small fw-semibold d-none d-xl-inline">{{ auth.user?.fullName }}</span></RouterLink>
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
const initials=computed(()=>auth.user?.fullName?.split(/\s+/).slice(-2).map(x=>x[0]).join('').toUpperCase() || 'HV')
function signOut() { auth.logout(); router.push('/login') }
</script>
<style scoped>
.lms-nav { box-shadow:0 3px 18px rgba(21,47,39,.055); }
.brand { display:flex; align-items:center; gap:.65rem; font-size:1.2rem; font-weight:850; }
.brand-mark { width:36px; height:36px; border-radius:9px; display:grid; place-items:center; background:#07875a; color:white; box-shadow:0 5px 15px rgba(7,135,90,.18) }
.nav-link { border-radius:7px; padding:.55rem .85rem !important; font-weight:650; color:#60716b; }
.nav-link.router-link-active { color:#07875a; background:#e9f6f1; }
.profile-link{padding:.25rem .5rem;border-radius:8px}.profile-link:hover{background:#f3f7f5}.lms-content{max-width:1320px}
</style>
