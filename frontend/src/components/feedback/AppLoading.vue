<template>
  <div class="app-feedback-state app-feedback-state--loading" role="status" aria-live="polite">
    <span class="app-feedback-state__icon"><span class="spinner-border spinner-border-sm"></span></span>
    <div>
      <strong>{{ title }}</strong>
      <p v-if="description">{{ description }}</p>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, default: 'Đang tải dữ liệu' },
  description: { type: String, default: '' }
})
</script>

<style scoped src="../../assets/css/components/feedback-states.css"></style>
