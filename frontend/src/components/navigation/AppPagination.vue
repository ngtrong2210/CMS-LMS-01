<template>
  <footer class="app-pagination" aria-label="Phân trang">
    <span class="app-pagination__summary"
      >Hiển thị <strong>{{ shownCount }}</strong> / {{ totalItems }} mục</span
    >
    <div class="app-pagination__controls">
      <button
        type="button"
        class="app-pagination__button"
        :disabled="page <= 1"
        aria-label="Trang trước"
        @click="$emit('previous')"
      >
        <i class="bi bi-chevron-left" aria-hidden="true"></i><span>Trước</span>
      </button>
      <span class="app-pagination__current"
        >Trang <strong>{{ page }}</strong> / {{ totalPages }}</span
      >
      <button
        type="button"
        class="app-pagination__button"
        :disabled="page >= totalPages"
        aria-label="Trang sau"
        @click="$emit('next')"
      >
        <span>Sau</span><i class="bi bi-chevron-right" aria-hidden="true"></i>
      </button>
    </div>
  </footer>
</template>

<script setup>
defineProps({
  page: { type: Number, required: true },
  totalPages: { type: Number, required: true },
  shownCount: { type: Number, default: 0 },
  totalItems: { type: Number, default: 0 }
})

defineEmits(['previous', 'next'])
</script>

<style scoped src="../../assets/css/components/pagination.css"></style>
