<template>
  <div class="cms-shell cms-theme">
    <aside class="sidebar d-none d-lg-flex flex-column">
      <RouterLink class="brand px-4" to="/cms/dashboard"><span class="brand-mark">L</span><span>LearnHub <small>CMS</small></span></RouterLink>
      <nav class="px-3 overflow-auto">
        <template v-for="group in menu" :key="group.label">
          <div class="menu-label">{{ group.label }}</div>
          <RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to"><i :class="['bi',item.icon]"></i><span>{{ item.text }}</span></RouterLink>
        </template>
      </nav>
      <div class="mt-auto p-3"><div class="support-card"><i class="bi bi-lightbulb-fill"></i><div><strong>Cần hỗ trợ?</strong><span>Trung tâm trợ giúp quản trị</span></div></div></div>
    </aside>
    <div class="cms-main">
      <header class="topbar bg-white d-flex align-items-center justify-content-between px-3 px-lg-4">
        <div class="d-flex align-items-center gap-3"><button class="btn btn-light d-lg-none menu-toggle" data-bs-toggle="offcanvas" data-bs-target="#mobileMenu" aria-label="Mở trình đơn"><i class="bi bi-list"></i></button><div><small class="text-secondary">Trang quản trị</small><div class="fw-bold">{{ route.meta.title || sectionTitle }}</div></div></div>
        <div class="d-flex align-items-center gap-2 gap-lg-3"><div class="top-search d-none d-xl-flex"><i class="bi bi-search"></i><input aria-label="Tìm kiếm" placeholder="Tìm kiếm nhanh..."></div><button class="icon-button" aria-label="Thông báo"><i class="bi bi-bell"></i><span></span></button><div class="d-none d-sm-flex align-items-center gap-2 user-summary"><span class="avatar">{{ initials }}</span><div><div class="small fw-bold">{{ auth.user?.fullName }}</div><div class="tiny">{{ roleName }}</div></div></div><button class="btn btn-light btn-sm logout-button" title="Đăng xuất" @click="signOut"><i class="bi bi-box-arrow-right"></i></button></div>
      </header>
      <main class="p-3 p-lg-4 page-content"><RouterView /></main>
    </div>
    <div id="mobileMenu" class="offcanvas offcanvas-start mobile-sidebar"><div class="offcanvas-header"><RouterLink class="brand" to="/cms/dashboard" data-bs-dismiss="offcanvas"><span class="brand-mark">L</span><span>LearnHub <small>CMS</small></span></RouterLink><button class="btn-close btn-close-white" data-bs-dismiss="offcanvas" aria-label="Đóng"></button></div><div class="offcanvas-body"><template v-for="group in menu" :key="group.label"><div class="menu-label">{{ group.label }}</div><RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to" data-bs-dismiss="offcanvas"><i :class="['bi',item.icon]"></i>{{ item.text }}</RouterLink></template></div></div>
  </div>
</template>
<script setup>
import { computed } from 'vue'; import { useRoute,useRouter } from 'vue-router'; import { useAuthStore } from '../stores/authStore'
const route=useRoute(), router=useRouter(), auth=useAuthStore(); const sectionTitle=computed(()=>route.params.section || 'Quản trị')
const initials=computed(()=>auth.user?.fullName?.split(/\s+/).slice(-2).map(x=>x[0]).join('').toUpperCase() || 'QT')
const roleName=computed(()=>({ADMIN:'Quản trị viên',TEACHER:'Giảng viên'})[auth.user?.role] || auth.user?.role)
const menu=[
 {label:'Tổng quan',items:[{to:'/cms/dashboard',text:'Bảng điều khiển',icon:'bi-grid'}]},
 {label:'Đào tạo',items:[{to:'/cms/courses',text:'Khóa học',icon:'bi-journal-bookmark'},{to:'/cms/lessons',text:'Chương / Bài học',icon:'bi-list-task'},{to:'/cms/videos/1/editor',text:'Video tương tác',icon:'bi-play-btn'},{to:'/cms/questions',text:'Ngân hàng câu hỏi',icon:'bi-patch-question'}]},
 {label:'Học viên',items:[{to:'/cms/students',text:'Danh sách học viên',icon:'bi-people'},{to:'/cms/enrollments',text:'Ghi danh khóa học',icon:'bi-person-plus'}]},
 {label:'Phân tích',items:[{to:'/cms/reports',text:'Báo cáo',icon:'bi-bar-chart'}]},
 {label:'Hệ thống',items:[{to:'/cms/users',text:'Người dùng',icon:'bi-person-gear'},{to:'/cms/roles',text:'Phân quyền',icon:'bi-shield-check'},{to:'/cms/settings',text:'Cài đặt',icon:'bi-gear'}]},
]
function signOut(){auth.logout();router.push('/login')}
</script>
<style scoped>
.cms-shell{min-height:100vh}.sidebar{position:fixed;inset:0 auto 0 0;width:268px;background:#005099;z-index:1020;color:#fff;box-shadow:6px 0 24px rgba(0,45,86,.08)}.cms-main{margin-left:268px;min-height:100vh}.topbar{height:72px;position:sticky;top:0;z-index:1010;box-shadow:0 3px 16px rgba(21,47,39,.055)}.brand{height:72px;display:flex;align-items:center;gap:.7rem;font-size:1.15rem;font-weight:850;color:#fff}.brand small{display:block;font-size:.62rem;color:#ffff1a;letter-spacing:.12em}.brand-mark{width:37px;height:37px;border-radius:9px;display:grid;place-items:center;background:#fff;color:#005099;box-shadow:0 5px 16px rgba(0,0,0,.12)}.sidebar nav{padding-bottom:1rem}.menu-label{font-size:.66rem;text-transform:uppercase;letter-spacing:.1em;color:rgba(255,255,255,.58);font-weight:800;margin:1.25rem .75rem .45rem}.side-link{display:flex;align-items:center;gap:.8rem;min-height:43px;padding:.68rem .8rem;border-radius:7px;color:rgba(255,255,255,.82);font-weight:600;margin:.16rem 0;transition:background .15s,color .15s}.side-link:hover{background:rgba(255,255,255,.11);color:#fff}.side-link.router-link-active{background:#fff;color:#005099;box-shadow:0 5px 14px rgba(0,31,59,.13)}.side-link i{font-size:1.08rem;width:20px;text-align:center}.support-card{display:flex;gap:.75rem;align-items:center;background:rgba(255,255,255,.12);color:#fff;border-radius:9px;padding:.85rem}.support-card>i{color:#ffff1a;font-size:1.2rem}.support-card div{display:grid}.support-card span{font-size:.72rem;color:rgba(255,255,255,.68)}.icon-button{position:relative;border:0;background:#f2f6f4;border-radius:8px;width:38px;height:38px;color:#315048}.icon-button span{position:absolute;width:7px;height:7px;border-radius:50%;background:#cd1b1b;right:8px;top:7px}.tiny{font-size:.68rem;color:#798a84}.top-search{height:40px;width:240px;align-items:center;gap:.65rem;background:#f3f6f5;border-radius:8px;padding:0 .85rem;color:#7c8c86}.top-search input{width:100%;border:0;outline:0;background:transparent;font-size:.84rem}.user-summary{padding-left:.25rem}.logout-button,.menu-toggle{width:38px;height:38px;padding:0}.mobile-sidebar{background:#005099;color:#fff;width:280px}.mobile-sidebar .offcanvas-header{height:72px}.mobile-sidebar .brand{height:auto}.page-content{max-width:1800px;margin:0 auto}@media(max-width:991px){.cms-main{margin-left:0}}
</style>
