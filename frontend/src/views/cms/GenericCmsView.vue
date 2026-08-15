<template>
  <section>
    <div class="app-card empty">
      <i :class="['bi', info.icon]"></i>
      <h1 class="page-title">{{ info.title }}</h1>
      <p class="page-subtitle">Phân hệ đã được định tuyến và sẵn sàng kết nối API quản trị.</p>
      <button class="btn btn-brand"><i class="bi bi-plus-lg"></i> Thêm dữ liệu mới</button>
    </div>
  </section>
</template>
<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
const route = useRoute()
const map = {
  lessons: ['Chương và bài học', 'bi-list-task'],
  enrollments: ['Ghi danh khóa học', 'bi-person-plus'],
  users: ['Quản lý người dùng', 'bi-person-gear'],
  roles: ['Vai trò và phân quyền', 'bi-shield-check'],
  settings: ['Cài đặt hệ thống', 'bi-gear']
}
const info = computed(() => {
  const value = map[route.params.section] || ['Quản trị', 'bi-grid']
  return { title: value[0], icon: value[1] }
})
</script>
<style scoped src="../../assets/css/pages/cms/generic.css"></style>
