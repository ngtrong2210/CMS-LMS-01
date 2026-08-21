<template>
  <div class="app-feedback-state app-feedback-state--empty">
    <span class="app-feedback-state__icon"><i :class="['bi', icon]" aria-hidden="true"></i></span>
    <div>
      <strong>{{ title }}</strong>
      <p v-if="description">{{ description }}</p>
      <div v-if="$slots.actions" class="app-feedback-state__actions"><slot name="actions" /></div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, default: 'Chưa có dữ liệu' },
  description: { type: String, default: '' },
  icon: { type: String, default: 'bi-inbox' }
})
</script>

<style scoped src="../../assets/css/components/feedback-states.css"></style>
