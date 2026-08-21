<template>
  <header class="app-page-header">
    <div class="app-page-header__content">
      <nav v-if="breadcrumbs.length" class="app-breadcrumb" aria-label="Điều hướng phân cấp">
        <template v-for="(item, index) in breadcrumbs" :key="`${item.label}-${index}`">
          <RouterLink v-if="item.to && index < breadcrumbs.length - 1" :to="item.to">{{ item.label }}</RouterLink>
          <span v-else :aria-current="index === breadcrumbs.length - 1 ? 'page' : undefined">{{ item.label }}</span>
          <i v-if="index < breadcrumbs.length - 1" class="bi bi-chevron-right" aria-hidden="true"></i>
        </template>
      </nav>

      <div v-if="eyebrow" class="app-page-header__eyebrow">
        <i v-if="icon" :class="['bi', icon]" aria-hidden="true"></i>
        <span>{{ eyebrow }}</span>
      </div>

      <h1 class="page-title">{{ title }}</h1>
      <p v-if="description" class="page-subtitle">{{ description }}</p>
    </div>

    <CmsPageActions v-if="$slots.actions" class="app-page-header__actions">
      <slot name="actions" />
    </CmsPageActions>
  </header>
</template>

<script setup>
import { RouterLink } from 'vue-router'
import CmsPageActions from './CmsPageActions.vue'

defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  eyebrow: { type: String, default: '' },
  icon: { type: String, default: '' },
  breadcrumbs: { type: Array, default: () => [] }
})
</script>

<style scoped src="../../assets/css/components/page-header.css"></style>
