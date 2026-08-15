<template>
  <section>
    <header class="d-flex justify-content-between align-items-end mb-4">
      <div>
        <h1 class="page-title mb-1">Báo cáo đào tạo</h1>
        <p class="page-subtitle mb-0">Phân tích hiệu quả học tập theo nhiều góc nhìn.</p>
      </div>
      <CmsPageActions>
        <button class="btn btn-action-export"><i class="bi bi-file-earmark-excel"></i> Xuất Excel</button>
      </CmsPageActions>
    </header>
    <div class="row g-3 mb-4">
      <div v-for="item in reports" :key="item.title" class="col-md-6 col-xl">
        <button class="report-card app-card" :class="{ active: active === item.title }" @click="active = item.title">
          <i :class="['bi', item.icon]"></i><span>{{ item.title }}</span>
        </button>
      </div>
    </div>
    <div class="app-card p-4">
      <div class="d-flex flex-wrap justify-content-between gap-3 mb-4">
        <div>
          <h2 class="h5 fw-bold">{{ active }}</h2>
          <small class="text-secondary">Dữ liệu cập nhật đến 11/08/2026</small>
        </div>
        <div class="d-flex gap-2">
          <select class="form-select">
            <option>Vue.js 3 từ cơ bản đến nâng cao</option></select
          ><select class="form-select">
            <option>30 ngày qua</option>
          </select>
        </div>
      </div>
      <div class="row g-3 mb-4">
        <div v-for="metric in metrics" :key="metric.label" class="col-6 col-lg-3">
          <div class="metric">
            <small>{{ metric.label }}</small
            ><strong>{{ metric.value }}</strong>
          </div>
        </div>
      </div>
      <div class="report-placeholder">
        <i class="bi bi-bar-chart-line"></i><strong>Biểu đồ {{ active }}</strong
        ><span>Dữ liệu chi tiết được tổng hợp theo bộ lọc đang chọn.</span>
        <div class="bars"><i v-for="n in 12" :key="n" :style="{ height: 30 + ((n * 17) % 65) + '%' }"></i></div>
      </div>
    </div>
  </section>
</template>
<script setup>
import { ref } from 'vue'
const reports = [
    { title: 'Tổng quan khóa học', icon: 'bi-journal-text' },
    { title: 'Tiến độ học viên', icon: 'bi-people' },
    { title: 'Hoàn thành bài học', icon: 'bi-check2-square' },
    { title: 'Hiệu quả câu hỏi', icon: 'bi-patch-question' },
    { title: 'Tương tác video', icon: 'bi-play-btn' }
  ],
  active = ref(reports[0].title),
  metrics = [
    { label: 'Lượt ghi danh', value: '1.284' },
    { label: 'Tỷ lệ hoàn thành', value: '68%' },
    { label: 'Điểm trung bình', value: '8.2' },
    { label: 'Thời gian học', value: '3.6 giờ' }
  ]
</script>
<style scoped src="../../assets/css/pages/cms/reports.css"></style>
