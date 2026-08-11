<template>
  <div class="cms-shell">
    <aside class="sidebar d-none d-lg-flex flex-column">
      <RouterLink class="brand p-4" to="/cms/dashboard"><span class="brand-mark">L</span><span>LearnHub <small>CMS</small></span></RouterLink>
      <nav class="px-3 overflow-auto">
        <template v-for="group in menu" :key="group.label">
          <div class="menu-label">{{ group.label }}</div>
          <RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to"><i :class="['bi',item.icon]"></i><span>{{ item.text }}</span></RouterLink>
        </template>
      </nav>
      <div class="mt-auto p-3"><div class="support-card"><i class="bi bi-lightbulb"></i><strong>Cần hỗ trợ?</strong><span>Trung tâm trợ giúp quản trị</span></div></div>
    </aside>
    <div class="cms-main">
      <header class="topbar bg-white d-flex align-items-center justify-content-between px-3 px-lg-4">
        <div class="d-flex align-items-center gap-3"><button class="btn btn-light d-lg-none" data-bs-toggle="offcanvas" data-bs-target="#mobileMenu"><i class="bi bi-list"></i></button><div><small class="text-secondary">Trang quản trị</small><div class="fw-bold">{{ route.meta.title || sectionTitle }}</div></div></div>
        <div class="d-flex align-items-center gap-3"><button class="icon-button"><i class="bi bi-bell"></i><span></span></button><div class="d-none d-sm-flex align-items-center gap-2"><span class="avatar">QT</span><div><div class="small fw-bold">{{ auth.user?.fullName }}</div><div class="tiny">{{ auth.user?.role }}</div></div></div><button class="btn btn-light btn-sm" @click="signOut"><i class="bi bi-box-arrow-right"></i></button></div>
      </header>
      <main class="p-3 p-lg-4"><RouterView /></main>
    </div>
    <div id="mobileMenu" class="offcanvas offcanvas-start"><div class="offcanvas-header"><strong>LearnHub CMS</strong><button class="btn-close" data-bs-dismiss="offcanvas"></button></div><div class="offcanvas-body"><template v-for="group in menu" :key="group.label"><div class="menu-label">{{ group.label }}</div><RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to" data-bs-dismiss="offcanvas"><i :class="['bi',item.icon]"></i>{{ item.text }}</RouterLink></template></div></div>
  </div>
</template>
<script setup>
import { computed } from 'vue'; import { useRoute,useRouter } from 'vue-router'; import { useAuthStore } from '../stores/authStore'
const route=useRoute(), router=useRouter(), auth=useAuthStore(); const sectionTitle=computed(()=>route.params.section || 'Quản trị')
const menu=[
 {label:'Tổng quan',items:[{to:'/cms/dashboard',text:'Bảng điều khiển',icon:'bi-grid'}]},
 {label:'Đào tạo',items:[{to:'/cms/courses',text:'Khóa học',icon:'bi-journal-bookmark'},{to:'/cms/lessons',text:'Chương / Bài học',icon:'bi-list-task'},{to:'/cms/videos/101/editor',text:'Video tương tác',icon:'bi-play-btn'},{to:'/cms/questions',text:'Ngân hàng câu hỏi',icon:'bi-patch-question'}]},
 {label:'Học viên',items:[{to:'/cms/students',text:'Danh sách học viên',icon:'bi-people'},{to:'/cms/enrollments',text:'Ghi danh khóa học',icon:'bi-person-plus'}]},
 {label:'Phân tích',items:[{to:'/cms/reports',text:'Báo cáo',icon:'bi-bar-chart'}]},
 {label:'Hệ thống',items:[{to:'/cms/users',text:'Người dùng',icon:'bi-person-gear'},{to:'/cms/roles',text:'Phân quyền',icon:'bi-shield-check'},{to:'/cms/settings',text:'Cài đặt',icon:'bi-gear'}]},
]
function signOut(){auth.logout();router.push('/login')}
</script>
<style scoped>
.cms-shell{min-height:100vh}.sidebar{position:fixed;inset:0 auto 0 0;width:260px;background:#fff;border-right:1px solid #e8eeeb;z-index:1020}.cms-main{margin-left:260px;min-height:100vh}.topbar{height:72px;border-bottom:1px solid #e8eeeb;position:sticky;top:0;z-index:1010}.brand{display:flex;align-items:center;gap:.7rem;font-size:1.15rem;font-weight:850}.brand small{font-size:.65rem;color:#07875a}.brand-mark{width:36px;height:36px;border-radius:10px;display:grid;place-items:center;background:#07875a;color:white}.menu-label{font-size:.68rem;text-transform:uppercase;letter-spacing:.08em;color:#9aa7a2;font-weight:800;margin:1.2rem .75rem .45rem}.side-link{display:flex;align-items:center;gap:.8rem;padding:.7rem .8rem;border-radius:9px;color:#5e7069;font-weight:600;margin:.15rem 0}.side-link:hover,.side-link.router-link-active{background:#e9f6f1;color:#07875a}.side-link i{font-size:1.05rem}.support-card{display:grid;gap:.3rem;background:#eaf2fa;color:#005099;border-radius:12px;padding:1rem}.support-card span{font-size:.76rem;color:#58758e}.icon-button{position:relative;border:0;background:#f3f6f5;border-radius:9px;width:38px;height:38px}.icon-button span{position:absolute;width:7px;height:7px;border-radius:50%;background:#cd1b1b;right:8px;top:7px}.tiny{font-size:.68rem;color:#798a84}@media(max-width:991px){.cms-main{margin-left:0}}
</style>
