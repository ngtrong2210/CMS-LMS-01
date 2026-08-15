<template>
  <section>
    <header class="search-page-header mb-4">
      <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
        <div>
          <span class="search-kicker"><i class="bi bi-stars"></i> TÌM KIẾM TOÀN HỆ THỐNG</span>
          <h1 class="page-title mb-1">Tìm nhanh dữ liệu quản trị</h1>
          <p class="page-subtitle mb-0">Tra cứu khóa học, bài học, video, câu hỏi và học viên từ một nơi.</p>
        </div>
        <CmsPageActions />
      </div>
      <form class="page-search" @submit.prevent="submitSearch">
        <i class="bi bi-search"></i>
        <input
          v-model="query"
          type="search"
          aria-label="Từ khóa tìm kiếm toàn hệ thống"
          placeholder="Nhập ít nhất 2 ký tự..."
          autocomplete="off"
        />
        <button class="btn btn-brand" :disabled="loading">
          <span v-if="loading" class="spinner-border spinner-border-sm"></span
          ><template v-else><i class="bi bi-search"></i> Tìm kiếm</template>
        </button>
      </form>
      <div v-if="validationMessage" class="search-validation">
        <i class="bi bi-info-circle"></i>{{ validationMessage }}
      </div>
    </header>

    <div v-if="error" class="alert alert-danger"><i class="bi bi-exclamation-triangle me-2"></i>{{ error }}</div>

    <template v-if="searchedTerm">
      <div class="search-summary app-card mb-3">
        <div>
          <span>KẾT QUẢ CHO</span><strong>“{{ searchedTerm }}”</strong>
        </div>
        <span class="result-total">{{ items.length }} kết quả</span>
      </div>

      <div class="type-tabs mb-3" role="tablist" aria-label="Lọc loại kết quả">
        <button
          v-for="type in types"
          :key="type.value"
          type="button"
          :class="['type-tab', { active: activeType === type.value }]"
          @click="activeType = type.value"
        >
          <i :class="['bi', type.icon]"></i>{{ type.label }} <span>{{ countByType(type.value) }}</span>
        </button>
      </div>

      <div v-if="loading" class="app-card search-state">
        <span class="spinner-border text-brand"></span>
        <p>Đang tìm trong dữ liệu SQL...</p>
      </div>
      <div v-else-if="filteredItems.length" class="result-list">
        <RouterLink
          v-for="item in filteredItems"
          :key="`${item.type}-${item.id}`"
          :to="item.targetUrl"
          class="result-card app-card"
        >
          <span :class="['result-icon', `type-${item.type.toLowerCase()}`]"><i :class="['bi', item.icon]"></i></span>
          <span class="result-copy">
            <span class="result-heading"
              ><span class="result-type">{{ typeLabel(item.type) }}</span
              ><span :class="['status-dot', statusClass(item.status)]">{{ statusLabel(item.status) }}</span></span
            >
            <strong>{{ item.title }}</strong>
            <small>{{ item.subtitle }}</small>
            <span v-if="item.description" class="result-description">{{ item.description }}</span>
          </span>
          <span class="result-open"><span>Mở</span><i class="bi bi-arrow-right"></i></span>
        </RouterLink>
      </div>
      <div v-else class="app-card search-state">
        <span class="empty-icon"><i class="bi bi-search"></i></span>
        <h2>Chưa tìm thấy dữ liệu phù hợp</h2>
        <p>Thử tìm bằng mã khóa học, tên bài học, nội dung câu hỏi, tên video hoặc mã học viên.</p>
      </div>
    </template>

    <div v-else class="search-guide">
      <article v-for="guide in guides" :key="guide.title" class="app-card guide-card">
        <span><i :class="['bi', guide.icon]"></i></span>
        <div>
          <strong>{{ guide.title }}</strong>
          <p>{{ guide.description }}</p>
          <small>Ví dụ: {{ guide.example }}</small>
        </div>
      </article>
    </div>
  </section>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axiosClient from '../../api/axiosClient'

const route = useRoute(),
  router = useRouter()
const query = ref(''),
  searchedTerm = ref(''),
  items = ref([]),
  loading = ref(false),
  error = ref(''),
  validationMessage = ref(''),
  activeType = ref('')
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const types = [
  { value: '', label: 'Tất cả', icon: 'bi-grid' },
  { value: 'COURSE', label: 'Khóa học', icon: 'bi-journal-bookmark' },
  { value: 'LESSON', label: 'Bài học', icon: 'bi-play-btn' },
  { value: 'VIDEO', label: 'Video', icon: 'bi-collection-play' },
  { value: 'QUESTION', label: 'Câu hỏi', icon: 'bi-patch-question' },
  { value: 'STUDENT', label: 'Học viên', icon: 'bi-people' }
]
const guides = [
  {
    title: 'Khóa học và bài học',
    icon: 'bi-journal-bookmark',
    description: 'Tìm theo mã, tiêu đề, chương, mô tả hoặc tên giảng viên.',
    example: 'VUE-001, Composition API'
  },
  {
    title: 'Video dùng chung',
    icon: 'bi-collection-play',
    description: 'Tìm theo tên hiển thị, tên tệp hoặc đường dẫn video trong thư viện.',
    example: 'Bài mở đầu, z3.mp4'
  },
  {
    title: 'Ngân hàng câu hỏi',
    icon: 'bi-patch-question',
    description: 'Tìm trực tiếp trong nội dung, giải thích, loại và độ khó câu hỏi.',
    example: 'Vue Router, SINGLE_CHOICE'
  },
  {
    title: 'Học viên',
    icon: 'bi-people',
    description: 'Tìm theo họ tên, mã học viên, tài khoản hoặc địa chỉ email.',
    example: 'HV001, Nguyễn Văn Học'
  }
]
const filteredItems = computed(() =>
  activeType.value ? items.value.filter((item) => item.type === activeType.value) : items.value
)
let requestId = 0

watch(
  () => route.query.q,
  async (value) => {
    const term = String(value || '').trim()
    query.value = term
    activeType.value = ''
    validationMessage.value = ''
    if (term.length < 2) {
      searchedTerm.value = ''
      items.value = []
      error.value = ''
      return
    }
    await runSearch(term)
  },
  { immediate: true }
)

async function runSearch(term) {
  const current = ++requestId
  loading.value = true
  error.value = ''
  searchedTerm.value = term
  try {
    const rows = await axiosClient.get('/cms/search', { params: { q: term, limit: 100, _fresh: Date.now() } })
    if (current !== requestId) return
    items.value = (Array.isArray(rows) ? rows : []).map((row) => ({
      type: pick(row, 'ResultType', 'resultType') || '',
      id: Number(pick(row, 'EntityId', 'entityId')),
      parentId: Number(pick(row, 'ParentId', 'parentId') || 0),
      title: pick(row, 'Title', 'title') || '',
      subtitle: pick(row, 'Subtitle', 'subtitle') || '',
      description: pick(row, 'Description', 'description') || '',
      status: pick(row, 'Status', 'status') || '',
      targetUrl: pick(row, 'TargetUrl', 'targetUrl') || '/cms/dashboard',
      icon: pick(row, 'Icon', 'icon') || 'bi-search'
    }))
  } catch (e) {
    if (current === requestId) {
      items.value = []
      error.value = e.message
    }
  } finally {
    if (current === requestId) loading.value = false
  }
}
function submitSearch() {
  const term = query.value.trim()
  if (term.length < 2) {
    validationMessage.value = 'Vui lòng nhập ít nhất 2 ký tự để tìm kiếm.'
    return
  }
  validationMessage.value = ''
  if (term === String(route.query.q || '').trim()) runSearch(term)
  else router.push({ path: '/cms/search', query: { q: term } })
}
function countByType(type) {
  return type ? items.value.filter((item) => item.type === type).length : items.value.length
}
function typeLabel(type) {
  return types.find((item) => item.value === type)?.label || type
}
function statusLabel(status) {
  return (
    {
      ACTIVE: 'Hoạt động',
      INACTIVE: 'Tạm ẩn',
      PUBLISHED: 'Đã xuất bản',
      DRAFT: 'Bản nháp',
      ARCHIVED: 'Lưu trữ',
      LOCKED: 'Đã khóa'
    }[status] ||
    status ||
    'Sẵn sàng'
  )
}
function statusClass(status) {
  return ['ACTIVE', 'PUBLISHED'].includes(status)
    ? 'active'
    : ['INACTIVE', 'LOCKED', 'ARCHIVED'].includes(status)
      ? 'inactive'
      : 'draft'
}
</script>

<style scoped src="../../assets/css/pages/cms/global-search.css"></style>
