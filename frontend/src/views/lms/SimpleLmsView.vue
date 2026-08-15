<template>
  <section>
    <div class="app-card empty">
      <i :class="['bi', route.meta.icon || 'bi-stars']"></i>
      <h1 class="page-title">{{ route.meta.title }}</h1>
      <p class="page-subtitle">Khu vực này đã sẵn sàng để đồng bộ dữ liệu từ hồ sơ học tập của bạn.</p>
      <RouterLink to="/lms/dashboard" class="btn btn-brand">Về tổng quan</RouterLink>
    </div>
  </section>
</template>
<script setup>
import { useRoute } from 'vue-router'
const route = useRoute()
</script>
<style scoped src="../../assets/css/pages/lms/simple.css"></style>
