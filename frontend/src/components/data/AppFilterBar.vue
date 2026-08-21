<template>
  <section class="app-filter-bar" aria-label="Bộ lọc dữ liệu">
    <div class="app-filter-bar__fields"><slot /></div>
    <div v-if="$slots.actions" class="app-filter-bar__actions"><slot name="actions" /></div>
  </section>
</template>

<style scoped src="../../assets/css/components/filter-bar.css"></style>
