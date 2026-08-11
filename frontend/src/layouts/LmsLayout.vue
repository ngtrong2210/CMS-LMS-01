<template>
  <div class="lms-shell">
    <div class="learning-strip"><div class="container"><span><i class="bi bi-mortarboard"></i> Hệ thống học tập trực tuyến LearnHub</span><span class="d-none d-md-inline"><i class="bi bi-headset"></i> Hỗ trợ học viên: Bộ phận đào tạo</span></div></div>
    <nav class="navbar navbar-expand-lg bg-white sticky-top lms-nav">
      <div class="container py-2">
        <RouterLink class="brand" to="/lms/dashboard"><img class="eduvers-logo" src="/images/eduvers/logo-2.png" alt="Eduvers"></RouterLink>
        <button class="navbar-toggler border-0" data-bs-toggle="collapse" data-bs-target="#lmsNav"><i class="bi bi-list fs-2"></i></button>
        <div id="lmsNav" class="collapse navbar-collapse">
          <div class="navbar-nav mx-auto gap-lg-2">
            <RouterLink class="nav-link" to="/lms/dashboard">Tổng quan</RouterLink>
            <RouterLink class="nav-link" to="/lms/courses">Khóa học của tôi</RouterLink>
            <RouterLink class="nav-link" to="/lms/results">Kết quả</RouterLink>
          </div>
          <div class="d-flex align-items-center gap-2 mt-3 mt-lg-0">
            <RouterLink to="/lms/profile" class="profile-link d-flex align-items-center gap-2"><img class="avatar user-avatar" :src="avatarUrl" :alt="`Ảnh đại diện ${auth.user?.fullName || ''}`"><span class="profile-copy d-none d-xl-grid"><strong>{{ auth.user?.fullName }}</strong><small>Học viên</small></span></RouterLink>
            <button class="btn btn-light btn-sm" title="Đăng xuất" @click="signOut"><i class="bi bi-box-arrow-right"></i></button>
          </div>
        </div>
      </div>
    </nav>
    <main class="container py-4 py-lg-5 lms-content"><RouterView /></main>
    <footer class="lms-footer"><div class="container"><span>© 2026 LearnHub · Hệ thống quản lý học tập</span><span>Hỗ trợ · Quy định học tập · Bảo mật</span></div></footer>
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
.brand-mark { width:38px; height:38px; border-radius:10px; display:block; object-fit:contain; box-shadow:0 5px 15px rgba(var(--eduvers-base-rgb),.18) }
.nav-link { border-radius:7px; padding:.55rem .85rem !important; font-weight:650; color:#60716b; }
.nav-link.router-link-active { color:var(--eduvers-base); background:rgba(var(--eduvers-base-rgb),.10); }
.profile-link{padding:.25rem .5rem;border-radius:8px}.profile-link:hover{background:#f3f7f5}.user-avatar{display:block;object-fit:cover;border:2px solid #fff;box-shadow:0 2px 9px rgba(18,54,43,.14)}.lms-content{max-width:1320px}
.lms-shell{min-height:100vh;display:flex;flex-direction:column;background:var(--eduvers-white)}.learning-strip{height:34px;display:flex;align-items:center;background:var(--eduvers-black);color:rgba(255,255,255,.78);font-size:.68rem}.learning-strip .container{display:flex;justify-content:space-between;align-items:center}.learning-strip i{margin-right:.35rem;color:var(--eduvers-base)}
.lms-nav{min-height:72px;border-bottom:1px solid var(--eduvers-bdr-color);box-shadow:none}.brand{color:var(--eduvers-black);font-size:1rem}.brand:hover{color:var(--eduvers-black)}.eduvers-logo{display:block;width:150px;height:auto}
.nav-link{position:relative;padding:.65rem 1rem!important;color:var(--eduvers-gray);border-radius:var(--eduvers-bdr-radius);font-size:.82rem;font-weight:700}.nav-link:hover{color:var(--eduvers-base);background:var(--eduvers-primary)}.nav-link.router-link-active{color:var(--eduvers-base);background:rgba(var(--eduvers-base-rgb),.10)}.profile-link{min-height:46px;padding:.28rem .65rem .28rem .3rem;background:var(--eduvers-primary);border-radius:var(--eduvers-bdr-radius)}.profile-link:hover{background:var(--eduvers-bdr-color)}.user-avatar{border:0;box-shadow:none}.profile-copy{line-height:1.15}.profile-copy strong{color:var(--eduvers-black);font-size:.75rem}.profile-copy small{margin-top:.2rem;color:var(--eduvers-gray);font-size:.62rem}
.lms-content{width:100%;max-width:1360px;flex:1}.lms-footer{padding:1.15rem 0;border-top:1px solid var(--eduvers-bdr-color);background:var(--eduvers-white);color:var(--eduvers-gray);font-size:.7rem}.lms-footer .container{display:flex;justify-content:space-between;gap:1rem}
@media(max-width:991px){.learning-strip{display:none}.lms-nav{min-height:66px}.navbar-collapse{padding:1rem 0}.navbar-nav{gap:.25rem}.lms-content{padding-top:1.25rem!important}.lms-footer .container{display:grid;text-align:center;justify-content:center}}
</style>
