<template>
  <main class="login-page">
    <aside class="system-panel">
      <div class="brand brand-lockup" aria-label="Thiên Hà Số">
        <img class="brand-symbol" src="/images/brand/thien-ha-so.png" alt="" />
        <span class="brand-name">Thiên Hà Số</span>
      </div>
      <div class="system-intro">
        <p class="eyebrow">HỆ THỐNG QUẢN LÝ HỌC TẬP</p>
        <h1>Không gian học tập dành cho học viên và giảng viên.</h1>
        <p>Truy cập bài giảng, thực hiện kiểm tra và theo dõi kết quả học tập trên cùng một hệ thống.</p>
        <ul class="system-features">
          <li>
            <i class="bi bi-collection-play"></i
            ><span
              ><strong>Khóa học và bài giảng</strong><small>Nội dung được tổ chức theo chương, bài học.</small></span
            >
          </li>
          <li>
            <i class="bi bi-patch-question"></i
            ><span
              ><strong>Video và câu hỏi tương tác</strong><small>Thực hành ngay trong quá trình xem bài.</small></span
            >
          </li>
          <li>
            <i class="bi bi-bar-chart"></i
            ><span><strong>Tiến độ và kết quả</strong><small>Theo dõi quá trình học tập theo thời gian.</small></span>
          </li>
        </ul>
      </div>
      <div class="support-box">
        <i class="bi bi-headset"></i
        ><span><small>Cần hỗ trợ đăng nhập?</small><strong>Liên hệ bộ phận quản trị đào tạo</strong></span>
      </div>
    </aside>
    <section class="form-panel">
      <div class="login-card">
        <div class="mobile-brand brand-lockup" aria-label="Thiên Hà Số">
          <img class="brand-symbol" src="/images/brand/thien-ha-so.png" alt="" />
          <span class="brand-name">Thiên Hà Số</span>
        </div>
        <header class="form-heading">
          <span>ĐĂNG NHẬP TÀI KHOẢN</span>
          <h2>Đăng nhập hệ thống</h2>
          <p>Sử dụng tài khoản được cấp để truy cập khóa học của bạn.</p>
        </header>
        <div v-if="error" class="alert alert-danger py-2"><i class="bi bi-exclamation-circle me-2"></i>{{ error }}</div>
        <form @submit.prevent="submit">
          <div class="field-group">
            <label class="form-label" for="username">Tên đăng nhập</label>
            <div class="input-wrap">
              <i class="bi bi-person"></i
              ><input
                id="username"
                v-model.trim="form.username"
                class="form-control"
                autocomplete="username"
                placeholder="Nhập tên đăng nhập"
                required
              />
            </div>
          </div>
          <div class="field-group">
            <label class="form-label" for="password">Mật khẩu</label>
            <div class="input-wrap">
              <i class="bi bi-lock"></i
              ><input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                class="form-control"
                autocomplete="current-password"
                placeholder="Nhập mật khẩu"
                required
              /><button
                type="button"
                :aria-label="showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'"
                @click="showPassword = !showPassword"
              >
                <i :class="['bi', showPassword ? 'bi-eye-slash' : 'bi-eye']"></i>
              </button>
            </div>
          </div>
          <div class="form-options">
            <label><input v-model="remember" class="form-check-input" type="checkbox" /> Ghi nhớ đăng nhập</label
            ><a href="#">Quên mật khẩu?</a>
          </div>
          <button class="btn btn-brand login-button w-100" :disabled="loading">
            <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span><span>Đăng nhập</span
            ><i v-if="!loading" class="bi bi-arrow-right"></i>
          </button>
        </form>
        <div class="demo-box">
          <div class="demo-heading"><strong>Tài khoản dùng thử</strong><small>Nhấn để điền nhanh</small></div>
          <div class="demo-accounts">
            <button
              v-for="item in demos"
              :key="item.username"
              type="button"
              class="demo-account"
              @click="useDemo(item)"
            >
              <span>{{ item.label }}</span
              ><code>{{ item.username }}</code>
            </button>
          </div>
          <p>Mật khẩu dùng chung: <strong>123456</strong></p>
        </div>
        <p class="security-note">
          <i class="bi bi-shield-check"></i> Không chia sẻ thông tin đăng nhập cho người khác.
        </p>
      </div>
      <footer>© 2026 Thiên Hà Số · Hệ thống quản lý học tập</footer>
    </section>
  </main>
</template>
<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/authStore'
const auth = useAuthStore(),
  router = useRouter(),
  form = reactive({ username: 'student', password: '123456' }),
  error = ref(''),
  loading = ref(false),
  showPassword = ref(false),
  remember = ref(true)
const demos = [
  { label: 'Học viên', username: 'student' },
  { label: 'Giảng viên', username: 'teacher' },
  { label: 'Quản trị', username: 'admin' }
]
function useDemo(item) {
  form.username = item.username
  form.password = '123456'
}
async function submit() {
  error.value = ''
  loading.value = true
  await new Promise((r) => setTimeout(r, 350))
  try {
    const user = await auth.login(form.username, form.password)
    router.push(user.role === 'STUDENT' ? '/lms/dashboard' : '/cms/dashboard')
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>
<style scoped src="../../assets/css/pages/auth/login.css"></style>
