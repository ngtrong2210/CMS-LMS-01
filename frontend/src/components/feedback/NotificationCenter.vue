<template>
  <div ref="centerRef" class="notification-center">
    <button
      type="button"
      class="icon-button notification-trigger"
      aria-label="Thông báo"
      :aria-expanded="open"
      @click="toggle"
    >
      <svg class="notification-bell-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path
          d="M18 8.75a6 6 0 0 0-12 0c0 7-3 7-3 8.75h18c0-1.75-3-1.75-3-8.75Z"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path d="M9.75 20a2.55 2.55 0 0 0 4.5 0" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
        <path d="M12 3V1.75" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
      </svg>
      <span v-if="unreadCount" class="notification-badge">{{ unreadCount > 99 ? '99+' : unreadCount }}</span>
    </button>

    <Transition name="notification-panel-fade">
      <section v-if="open" class="notification-panel" aria-label="Danh sách thông báo">
        <header class="notification-header">
          <div>
            <small>Trung tâm thông báo</small>
            <h2>Thông báo</h2>
          </div>
          <button
            v-if="unreadCount"
            type="button"
            class="notification-read-all"
            :disabled="markingAll"
            @click="markAllRead"
          >
            <i class="bi bi-check2-all"></i> Đọc tất cả
          </button>
        </header>

        <div class="notification-tabs" role="tablist" aria-label="Bộ lọc thông báo">
          <button type="button" :class="{ active: !unreadOnly }" @click="changeFilter(false)">Tất cả</button>
          <button type="button" :class="{ active: unreadOnly }" @click="changeFilter(true)">
            Chưa đọc <span>{{ unreadCount }}</span>
          </button>
        </div>

        <div class="notification-list">
          <div v-if="loading" class="notification-state">
            <span class="spinner-border spinner-border-sm"></span>
            <span>Đang tải thông báo...</span>
          </div>
          <div v-else-if="error" class="notification-state is-error">
            <i class="bi bi-wifi-off"></i>
            <span>{{ error }}</span>
            <button type="button" @click="load">Thử lại</button>
          </div>
          <div v-else-if="!items.length" class="notification-state">
            <i class="bi bi-bell-slash"></i>
            <strong>{{ unreadOnly ? 'Không còn thông báo chưa đọc' : 'Chưa có thông báo' }}</strong>
            <span>Các hoạt động học tập mới sẽ xuất hiện tại đây.</span>
          </div>
          <button
            v-for="item in items"
            v-else
            :key="item.id"
            type="button"
            :class="['notification-item', { unread: !item.isRead }]"
            @click="openNotification(item)"
          >
            <span :class="['notification-type-icon', typeClass(item.notificationType)]">
              <i :class="['bi', typeIcon(item.notificationType)]"></i>
            </span>
            <span class="notification-copy">
              <strong>{{ item.title }}</strong>
              <span>{{ item.message }}</span>
              <small>
                <i class="bi bi-clock"></i>{{ relativeTime(item.createdAt) }}
                <template v-if="item.actorName"> · {{ item.actorName }}</template>
              </small>
            </span>
            <span v-if="!item.isRead" class="notification-unread-dot" aria-label="Chưa đọc"></span>
          </button>
        </div>

        <footer class="notification-footer"><i class="bi bi-arrow-repeat"></i> Tự động cập nhật mỗi phút</footer>
      </section>
    </Transition>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import axiosClient from '../../api/axiosClient'

const router = useRouter()
const centerRef = ref(null)
const open = ref(false)
const loading = ref(false)
const markingAll = ref(false)
const unreadOnly = ref(false)
const unreadCount = ref(0)
const items = ref([])
const error = ref('')

let refreshTimer

onMounted(() => {
  load()
  refreshTimer = window.setInterval(load, 60000)
  document.addEventListener('click', handleOutsideClick)
})

onBeforeUnmount(() => {
  window.clearInterval(refreshTimer)
  document.removeEventListener('click', handleOutsideClick)
})

async function load() {
  loading.value = !items.value.length
  error.value = ''
  try {
    const feed = await axiosClient.get('/notifications', {
      params: { limit: 30, unreadOnly: unreadOnly.value }
    })
    items.value = feed.items || []
    unreadCount.value = Number(feed.unreadCount || 0)
  } catch (loadError) {
    error.value = loadError.message || 'Không thể tải thông báo.'
  } finally {
    loading.value = false
  }
}

async function toggle() {
  open.value = !open.value
  if (open.value) await load()
}

async function changeFilter(value) {
  if (unreadOnly.value === value) return
  unreadOnly.value = value
  await load()
}

async function openNotification(item) {
  if (!item.isRead) {
    try {
      await axiosClient.put(`/notifications/${item.id}/read`)
      item.isRead = true
      unreadCount.value = Math.max(0, unreadCount.value - 1)
      if (unreadOnly.value) items.value = items.value.filter((notification) => notification.id !== item.id)
    } catch (markError) {
      error.value = markError.message || 'Không thể đánh dấu đã đọc.'
      return
    }
  }

  open.value = false
  if (item.actionUrl?.startsWith('/')) await router.push(item.actionUrl)
}

async function markAllRead() {
  markingAll.value = true
  try {
    await axiosClient.put('/notifications/read-all')
    unreadCount.value = 0
    items.value = unreadOnly.value ? [] : items.value.map((item) => ({ ...item, isRead: true }))
  } catch (markError) {
    error.value = markError.message || 'Không thể đánh dấu tất cả đã đọc.'
  } finally {
    markingAll.value = false
  }
}

function handleOutsideClick(event) {
  if (open.value && !centerRef.value?.contains(event.target)) open.value = false
}

function typeIcon(type) {
  return (
    {
      ANSWER_SUBMITTED: 'bi-ui-checks',
      LESSON_COMPLETED: 'bi-trophy',
      ENROLLMENT: 'bi-person-check',
      VIDEO_SHARED: 'bi-share',
      SYSTEM: 'bi-gear'
    }[type] || 'bi-bell'
  )
}

function typeClass(type) {
  return (
    {
      ANSWER_SUBMITTED: 'is-blue',
      LESSON_COMPLETED: 'is-green',
      ENROLLMENT: 'is-red',
      VIDEO_SHARED: 'is-teal',
      SYSTEM: 'is-yellow'
    }[type] || 'is-blue'
  )
}

function relativeTime(value) {
  if (!value) return ''
  const normalized = /(?:Z|[+-]\d{2}:?\d{2})$/i.test(value) ? value : `${value}Z`
  const date = new Date(normalized)
  const seconds = Math.max(0, Math.round((Date.now() - date.getTime()) / 1000))
  if (!Number.isFinite(seconds) || seconds < 60) return 'Vừa xong'
  if (seconds < 3600) return `${Math.floor(seconds / 60)} phút trước`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)} giờ trước`
  if (seconds < 604800) return `${Math.floor(seconds / 86400)} ngày trước`
  return new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(date)
}
</script>
