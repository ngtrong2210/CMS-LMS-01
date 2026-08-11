<template>
  <div class="cms-shell cms-theme">
    <aside class="sidebar d-none d-lg-flex flex-column">
      <RouterLink class="brand px-4" to="/cms/dashboard"><img class="eduvers-logo" src="/images/eduvers/logo-2.png" alt="Eduvers"></RouterLink>
      <nav class="px-3 overflow-auto">
        <template v-for="group in menu" :key="group.label">
          <div class="menu-label">{{ group.label }}</div>
          <RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to"><i :class="['bi',item.icon]"></i><span>{{ item.text }}</span></RouterLink>
        </template>
      </nav>
    </aside>
    <div class="cms-main">
      <header class="topbar bg-white d-flex align-items-center justify-content-between px-3 px-lg-4">
        <div class="topbar-heading d-flex align-items-center gap-3"><button class="btn btn-light d-lg-none menu-toggle" data-bs-toggle="offcanvas" data-bs-target="#mobileMenu" aria-label="Mở trình đơn"><i class="bi bi-list"></i></button><div><small>KHÔNG GIAN QUẢN TRỊ</small><div>{{ route.meta.title || sectionTitle }}</div></div></div>
        <div class="topbar-actions d-flex align-items-center gap-2 gap-lg-3"><div class="top-search d-none d-xl-flex"><i class="bi bi-search"></i><input aria-label="Tìm kiếm" placeholder="Tìm kiếm trong hệ thống..."></div><button class="icon-button" aria-label="Thông báo"><i class="bi bi-bell"></i><span></span></button><div class="d-none d-sm-flex align-items-center gap-2 user-summary"><img class="avatar user-avatar" :src="avatarUrl" :alt="`Ảnh đại diện ${auth.user?.fullName || ''}`"><div><div class="small fw-bold">{{ auth.user?.fullName }}</div><div class="tiny">{{ roleName }}</div></div></div><button class="btn btn-light btn-sm logout-button" title="Đăng xuất" @click="signOut"><i class="bi bi-box-arrow-right"></i></button></div>
      </header>
      <main class="p-3 p-lg-4 page-content"><RouterView /></main>
    </div>
    <div id="mobileMenu" class="offcanvas offcanvas-start mobile-sidebar"><div class="offcanvas-header"><RouterLink class="brand" to="/cms/dashboard" data-bs-dismiss="offcanvas"><img class="eduvers-logo" src="/images/eduvers/logo-2.png" alt="Eduvers"></RouterLink><button class="btn-close" data-bs-dismiss="offcanvas" aria-label="Đóng"></button></div><div class="offcanvas-body"><template v-for="group in menu" :key="group.label"><div class="menu-label">{{ group.label }}</div><RouterLink v-for="item in group.items" :key="item.to" class="side-link" :to="item.to" data-bs-dismiss="offcanvas"><i :class="['bi',item.icon]"></i>{{ item.text }}</RouterLink></template></div></div>
  </div>
</template>
<script setup>
import { computed } from 'vue'; import { useRoute,useRouter } from 'vue-router'; import { useAuthStore } from '../stores/authStore'
const route=useRoute(), router=useRouter(), auth=useAuthStore(); const sectionTitle=computed(()=>route.params.section || 'Quản trị')
const avatarUrl=computed(()=>({ADMIN:'/images/avatar-admin.jpg',TEACHER:'/images/avatar-teacher.jpg',STUDENT:'/images/avatar-student.jpg'})[auth.user?.role] || '/images/avatar-admin.jpg')
const roleName=computed(()=>({ADMIN:'Quản trị viên',TEACHER:'Giảng viên'})[auth.user?.role] || auth.user?.role)
const menu=[
 {label:'Tổng quan',items:[{to:'/cms/dashboard',text:'Bảng điều khiển',icon:'bi-grid'}]},
 {label:'Đào tạo',items:[{to:'/cms/courses',text:'Khóa học',icon:'bi-journal-bookmark'},{to:'/cms/videos',text:'Thư viện video',icon:'bi-collection-play'},{to:'/cms/questions',text:'Ngân hàng câu hỏi',icon:'bi-patch-question'}]},
 {label:'Học viên',items:[{to:'/cms/students',text:'Danh sách học viên',icon:'bi-people'},{to:'/cms/enrollments',text:'Ghi danh khóa học',icon:'bi-person-plus'}]},
 {label:'Phân tích',items:[{to:'/cms/reports',text:'Báo cáo',icon:'bi-bar-chart'}]},
 {label:'Hệ thống',items:[{to:'/cms/users',text:'Người dùng',icon:'bi-person-gear'},{to:'/cms/roles',text:'Phân quyền',icon:'bi-shield-check'},{to:'/cms/settings',text:'Cài đặt',icon:'bi-gear'}]},
]
function signOut(){auth.logout();router.push('/login')}
</script>
<style scoped>
.cms-shell{min-height:100vh}.sidebar{position:fixed;inset:0 auto 0 0;width:268px;background:var(--eduvers-black);z-index:1020;color:#fff;box-shadow:6px 0 24px rgba(0,45,86,.08)}.cms-main{margin-left:268px;min-height:100vh}.topbar{height:72px;position:sticky;top:0;z-index:1010;box-shadow:0 3px 16px rgba(21,47,39,.055)}.brand{height:72px;display:flex;align-items:center;gap:.7rem;font-size:1.15rem;font-weight:850;color:#fff}.brand small{display:block;font-size:.62rem;color:#ffc224;letter-spacing:.12em}.brand-mark{width:39px;height:39px;border-radius:10px;display:block;object-fit:contain;box-shadow:0 5px 16px rgba(0,0,0,.15)}.sidebar nav{padding-bottom:1rem}.menu-label{font-size:.66rem;text-transform:uppercase;letter-spacing:.1em;color:rgba(255,255,255,.58);font-weight:800;margin:1.25rem .75rem .45rem}.side-link{display:flex;align-items:center;gap:.8rem;min-height:43px;padding:.68rem .8rem;border-radius:7px;color:rgba(255,255,255,.82);font-weight:600;margin:.16rem 0;transition:background .15s,color .15s}.side-link:hover{background:rgba(255,255,255,.11);color:#fff}.side-link.router-link-active{background:#fff;color:var(--eduvers-black);box-shadow:0 5px 14px rgba(0,31,59,.13)}.side-link i{font-size:1.08rem;width:20px;text-align:center}.support-card{display:flex;gap:.75rem;align-items:center;background:rgba(255,255,255,.12);color:#fff;border-radius:9px;padding:.85rem}.support-card>i{color:#ffc224;font-size:1.2rem}.support-card div{display:grid}.support-card span{font-size:.72rem;color:rgba(255,255,255,.68)}.icon-button{position:relative;border:0;background:#f2f6f4;border-radius:8px;width:38px;height:38px;color:#315048}.icon-button span{position:absolute;width:7px;height:7px;border-radius:50%;background:var(--eduvers-base);right:8px;top:7px}.tiny{font-size:.68rem;color:#798a84}.top-search{height:40px;width:240px;align-items:center;gap:.65rem;background:#f3f6f5;border-radius:8px;padding:0 .85rem;color:#7c8c86}.top-search input{width:100%;border:0;outline:0;background:transparent;font-size:.84rem}.user-summary{padding-left:.25rem}.user-avatar{display:block;object-fit:cover;border:2px solid #fff;box-shadow:0 2px 9px rgba(18,54,43,.14)}.logout-button,.menu-toggle{width:38px;height:38px;padding:0}.mobile-sidebar{background:var(--eduvers-black);color:#fff;width:280px}.mobile-sidebar .offcanvas-header{height:72px}.mobile-sidebar .brand{height:auto}.page-content{max-width:1800px;margin:0 auto}@media(max-width:991px){.cms-main{margin-left:0}}
.sidebar{width:276px;background:var(--eduvers-white);color:var(--eduvers-black);border-right:1px solid var(--eduvers-bdr-color);box-shadow:10px 0 35px rgba(13,41,68,.035)}
.cms-main{margin-left:276px;background:var(--eduvers-primary)}
.brand{height:78px;color:var(--eduvers-black);border-bottom:1px solid var(--eduvers-bdr-color);font-size:1rem;font-weight:700}
.brand:hover{color:var(--eduvers-black)}.brand>span{display:grid;line-height:1.1}.brand strong{font-size:1.08rem}.brand small{margin-top:.3rem;color:var(--eduvers-base);font-size:.58rem;font-weight:750;letter-spacing:.08em}
.eduvers-logo{display:block;width:150px;height:auto}
.sidebar nav{padding-top:.4rem;padding-bottom:1rem}.menu-label{margin:1.35rem .85rem .5rem;color:#9a9f9d;font-size:.62rem;font-weight:750;letter-spacing:.11em}
.side-link{min-height:44px;margin:.18rem 0;padding:.65rem .75rem;color:#56635f;border-radius:8px;font-weight:650}
.side-link:hover{color:var(--eduvers-black);background:var(--eduvers-primary)}.side-link.router-link-active{color:var(--eduvers-base);background:rgba(var(--eduvers-base-rgb),.10);box-shadow:none}
.side-link i{width:30px;height:30px;display:grid;place-items:center;border-radius:var(--eduvers-bdr-radius);background:var(--eduvers-primary);color:var(--eduvers-gray);font-size:.96rem}.side-link.router-link-active i{background:var(--eduvers-white);color:var(--eduvers-base)}
.support-card{padding:1rem;background:var(--eduvers-black);border-radius:var(--eduvers-bdr-radius)}.support-card>i{width:34px;height:34px;display:grid;place-items:center;border-radius:var(--eduvers-bdr-radius);background:rgba(255,255,255,.1);color:var(--eduvers-base);font-size:1rem}.support-card strong{font-size:.78rem}.support-card span{color:rgba(255,255,255,.66);font-size:.66rem}
.topbar{height:78px;border-bottom:1px solid var(--eduvers-bdr-color);box-shadow:none}.topbar-heading small{display:block;color:var(--eduvers-base);font-size:.58rem;font-weight:750;letter-spacing:.11em}.topbar-heading div>div{color:var(--eduvers-black);font-size:.95rem;font-weight:700}
.top-search{width:270px;height:42px;background:#f8f4f2;color:#7b8581}.top-search input{color:#34433e;font-size:.79rem}.icon-button{width:40px;height:40px;background:#f8f4f2;color:#0d2944}.user-summary{min-height:46px;padding:.25rem .65rem .25rem .35rem;border-radius:9px;background:#f8f4f2}.user-avatar{border:0;box-shadow:none}.tiny{color:#7b8581}.logout-button,.menu-toggle{width:40px;height:40px;background:#f8f4f2}
.page-content{max-width:1840px;padding:1.75rem!important}.mobile-sidebar{width:288px;background:var(--eduvers-white);color:var(--eduvers-black)}.mobile-sidebar .offcanvas-header{height:78px;border-bottom:1px solid var(--eduvers-bdr-color)}.mobile-sidebar .brand{border:0}
@media(max-width:991px){.cms-main{margin-left:0}.page-content{padding:1.15rem!important}.topbar{height:68px}.topbar-heading small{display:none}}
</style>
