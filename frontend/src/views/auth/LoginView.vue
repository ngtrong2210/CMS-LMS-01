<template>
  <main class="login-page">
    <section class="login-panel">
      <div class="brand mb-5"><span class="brand-mark">L</span><span>LearnHub</span></div>
      <div class="mb-4"><div class="eyebrow">NỀN TẢNG ĐÀO TẠO TRỰC TUYẾN</div><h1>Học tập hiệu quả,<br><span>phát triển mỗi ngày.</span></h1><p>Quản lý lộ trình, theo dõi tiến độ và chinh phục kiến thức theo cách của bạn.</p></div>
      <div class="feature-grid"><div><i class="bi bi-play-circle"></i><span><strong>Video tương tác</strong><small>Học và thực hành tức thì</small></span></div><div><i class="bi bi-graph-up-arrow"></i><span><strong>Theo dõi tiến độ</strong><small>Nắm rõ kết quả học tập</small></span></div><div><i class="bi bi-patch-check"></i><span><strong>Chứng nhận</strong><small>Ghi nhận mọi thành tựu</small></span></div></div>
      <div class="brand-dots"><span></span><span></span><span></span><span></span></div>
    </section>
    <section class="form-panel">
      <div class="login-card">
        <div class="mobile-brand mb-4"><span class="brand-mark">L</span><strong>LearnHub</strong></div>
        <h2>Chào mừng trở lại</h2><p class="text-secondary mb-4">Đăng nhập để tiếp tục hành trình học tập.</p>
        <div v-if="error" class="alert alert-danger py-2"><i class="bi bi-exclamation-circle me-2"></i>{{ error }}</div>
        <form @submit.prevent="submit">
          <div class="mb-3"><label class="form-label fw-semibold">Tên đăng nhập</label><div class="input-wrap"><i class="bi bi-person"></i><input v-model.trim="form.username" class="form-control" autocomplete="username" placeholder="Nhập tên đăng nhập" required></div></div>
          <div class="mb-2"><label class="form-label fw-semibold">Mật khẩu</label><div class="input-wrap"><i class="bi bi-lock"></i><input v-model="form.password" :type="showPassword?'text':'password'" class="form-control" autocomplete="current-password" placeholder="Nhập mật khẩu" required><button type="button" @click="showPassword=!showPassword"><i :class="['bi',showPassword?'bi-eye-slash':'bi-eye']"></i></button></div></div>
          <div class="d-flex justify-content-between align-items-center mb-4"><label class="small"><input v-model="remember" class="form-check-input me-1" type="checkbox"> Ghi nhớ đăng nhập</label><a class="small text-brand fw-semibold" href="#">Quên mật khẩu?</a></div>
          <button class="btn btn-brand w-100" :disabled="loading"><span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>Đăng nhập <i v-if="!loading" class="bi bi-arrow-right ms-2"></i></button>
        </form>
        <div class="demo-box mt-4"><strong>Tài khoản trải nghiệm</strong><div class="d-flex flex-wrap gap-2 mt-2"><button v-for="item in demos" :key="item.username" class="demo-chip" @click="useDemo(item)">{{ item.label }} <small>{{ item.username }}</small></button></div><small>Mật khẩu chung: <b>123456</b></small></div>
      </div>
    </section>
  </main>
</template>
<script setup>
import { reactive,ref } from 'vue'; import { useRouter } from 'vue-router'; import { useAuthStore } from '../../stores/authStore'
const auth=useAuthStore(),router=useRouter(),form=reactive({username:'student',password:'123456'}),error=ref(''),loading=ref(false),showPassword=ref(false),remember=ref(true)
const demos=[{label:'Học viên',username:'student'},{label:'Giảng viên',username:'teacher'},{label:'Quản trị',username:'admin'}]
function useDemo(item){form.username=item.username;form.password='123456'}
async function submit(){error.value='';loading.value=true;await new Promise(r=>setTimeout(r,350));try{const user=await auth.login(form.username,form.password);router.push(user.role==='STUDENT'?'/lms/dashboard':'/cms/dashboard')}catch(e){error.value=e.message}finally{loading.value=false}}
</script>
<style scoped>
.login-page{min-height:100vh;display:grid;grid-template-columns:1.05fr .95fr;background:white}.login-panel{position:relative;overflow:hidden;padding:4.5rem clamp(2.5rem,6vw,7rem);color:white;background:linear-gradient(145deg,#07875a 0%,#056d52 62%,#005099 150%);display:flex;flex-direction:column;justify-content:center}.brand,.mobile-brand{display:flex;align-items:center;gap:.7rem;font-size:1.3rem;font-weight:850}.brand-mark{width:40px;height:40px;border-radius:11px;background:#ffff1a;color:#173f32;display:grid;place-items:center;font-weight:900}.eyebrow{font-size:.76rem;letter-spacing:.15em;font-weight:800;color:#b8ead8;margin-bottom:1rem}.login-panel h1{font-size:clamp(2.5rem,4.5vw,4.5rem);font-weight:850;line-height:1.08;letter-spacing:-.05em}.login-panel h1 span{color:#ffff1a}.login-panel p{max-width:560px;color:#d8eee6;font-size:1.08rem}.feature-grid{display:grid;gap:1rem;margin-top:2rem}.feature-grid>div{display:flex;gap:1rem;align-items:center}.feature-grid i{font-size:1.4rem;width:46px;height:46px;border-radius:12px;background:rgba(255,255,255,.12);display:grid;place-items:center}.feature-grid span{display:grid}.feature-grid small{color:#c7e5da}.brand-dots{position:absolute;right:8%;bottom:8%;display:flex;gap:.55rem}.brand-dots span{width:14px;height:14px;border-radius:50%;background:#fff}.brand-dots span:nth-child(2){background:#ffff1a}.brand-dots span:nth-child(3){background:#cd1b1b}.brand-dots span:nth-child(4){background:#005099}.form-panel{display:grid;place-items:center;padding:2rem}.login-card{width:min(440px,100%)}.login-card h2{font-weight:850;letter-spacing:-.03em}.input-wrap{position:relative}.input-wrap>i{position:absolute;left:14px;top:12px;color:#81918b;z-index:2}.input-wrap input{padding-left:42px;padding-right:42px}.input-wrap button{position:absolute;right:7px;top:5px;width:35px;height:35px;border:0;background:transparent}.demo-box{background:#f3f7f5;border-radius:12px;padding:1rem;color:#60716b}.demo-chip{border:0;background:white;border-radius:8px;padding:.45rem .65rem;color:#18332b;font-weight:700}.demo-chip small{display:block;color:#07875a}.mobile-brand{display:none;color:#173f32}@media(max-width:900px){.login-page{grid-template-columns:1fr}.login-panel{display:none}.form-panel{min-height:100vh}.mobile-brand{display:flex}}
</style>
