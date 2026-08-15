import { nextTick, onActivated, onBeforeUnmount, onDeactivated, onMounted, watch } from 'vue'

const CACHE_PREFIX = 'elearning:list-state:'

function readCache(cacheKey) {
  try {
    return JSON.parse(sessionStorage.getItem(`${CACHE_PREFIX}${cacheKey}`) || '{}')
  } catch {
    return {}
  }
}

export function useListViewState(cacheKey, fields) {
  const cached = readCache(cacheKey)
  const fieldEntries = Object.entries(fields)

  fieldEntries.forEach(([name, field]) => {
    if (Object.prototype.hasOwnProperty.call(cached.values || {}, name)) field.value = cached.values[name]
  })

  function saveState() {
    const values = Object.fromEntries(fieldEntries.map(([name, field]) => [name, field.value]))
    sessionStorage.setItem(
      `${CACHE_PREFIX}${cacheKey}`,
      JSON.stringify({ values, scrollY: Math.max(0, window.scrollY), updatedAt: Date.now() })
    )
  }

  function restorePosition() {
    const scrollY = Number(readCache(cacheKey).scrollY || 0)
    if (!scrollY) return

    nextTick(() => {
      window.requestAnimationFrame(() => window.scrollTo({ top: scrollY, behavior: 'auto' }))
      window.setTimeout(() => window.scrollTo({ top: scrollY, behavior: 'auto' }), 180)
    })
  }

  const stopWatching = watch(
    fieldEntries.map(([, field]) => field),
    saveState,
    { deep: true, flush: 'sync' }
  )

  onMounted(restorePosition)
  onActivated(restorePosition)
  onDeactivated(saveState)
  onBeforeUnmount(() => {
    saveState()
    stopWatching()
  })

  return {
    restoreListPosition: restorePosition,
    clearListState() {
      sessionStorage.removeItem(`${CACHE_PREFIX}${cacheKey}`)
    }
  }
}
