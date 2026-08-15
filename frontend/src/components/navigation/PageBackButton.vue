<template>
  <button type="button" class="page-back-button" :title="label" :aria-label="label" @click="goBack">
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="m14.5 5-7 7 7 7"></path>
    </svg>
    <span class="d-none d-md-inline">Trở về</span>
  </button>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const props = defineProps({
  fallback: { type: String, default: '' },
  label: { type: String, default: 'Trở về trang trước' }
})

const route = useRoute()
const router = useRouter()

const fallbackTarget = computed(() => {
  const configuredTarget = route.meta.backTo
  if (typeof configuredTarget === 'function') return configuredTarget(route)
  if (typeof configuredTarget === 'string') return configuredTarget
  if (props.fallback) return props.fallback
  return route.path.startsWith('/lms') ? '/lms/dashboard' : '/cms/dashboard'
})

function goBack() {
  const previousPath = window.history.state?.back
  const canUseHistory = previousPath && previousPath !== route.fullPath && previousPath !== '/login'

  if (canUseHistory) router.back()
  else router.push(fallbackTarget.value)
}
</script>

<style scoped src="../../assets/css/components/page-back-button.css"></style>
