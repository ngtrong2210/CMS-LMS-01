<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title mb-1">Phân học viên vào khóa học</h1>
        <p class="page-subtitle mb-0">Ghi danh học viên để cấp quyền truy cập khóa học và theo dõi tiến độ.</p>
      </div>
      <CmsPageActions>
        <button class="btn btn-action-create" @click="openForm">
          <i class="bi bi-person-plus me-1"></i> Phân học viên
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="summary-grid mb-3">
      <article class="app-card summary-card">
        <span class="summary-icon"><i class="bi bi-people"></i></span>
        <div>
          <small>Đang tham gia</small><strong>{{ activeCount }}</strong>
        </div>
      </article>
      <article class="app-card summary-card">
        <span class="summary-icon secondary"><i class="bi bi-mortarboard"></i></span>
        <div>
          <small>Khóa học có học viên</small><strong>{{ courseCount }}</strong>
        </div>
      </article>
      <article class="app-card summary-card">
        <span class="summary-icon soft"><i class="bi bi-check-circle"></i></span>
        <div>
          <small>Đã hoàn thành</small><strong>{{ completedCount }}</strong>
        </div>
      </article>
    </div>

    <div class="app-card p-3 mb-3">
      <div class="row g-2">
        <div class="col-lg-6">
          <div class="search-box">
            <i class="bi bi-search"></i
            ><input
              v-model.trim="search"
              class="form-control"
              placeholder="Tìm học viên, mã học viên hoặc khóa học..."
            />
          </div>
        </div>
        <div class="col-md-3">
          <select v-model="courseFilter" class="form-select">
            <option value="">Tất cả khóa học</option>
            <option v-for="course in courses" :key="course.id" :value="course.id">
              {{ course.code }} — {{ course.title }}
            </option>
          </select>
        </div>
        <div class="col-md-3">
          <select v-model="statusFilter" class="form-select">
            <option value="">Tất cả trạng thái</option>
            <option value="ENROLLED">Đã ghi danh</option>
            <option value="IN_PROGRESS">Đang học</option>
            <option value="COMPLETED">Hoàn thành</option>
            <option value="CANCELLED">Đã hủy</option>
          </select>
        </div>
      </div>
    </div>

    <div class="app-card p-2">
      <div class="table-responsive">
        <table class="table align-middle mb-0">
          <thead>
            <tr>
              <th>Học viên</th>
              <th>Khóa học</th>
              <th>Ngày ghi danh</th>
              <th>Tiến độ</th>
              <th>Điểm</th>
              <th>Trạng thái</th>
              <th class="text-end">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredItems" :key="item.id">
              <td>
                <div class="student-cell">
                  <span class="avatar">{{ initials(item.studentName) }}</span>
                  <div>
                    <strong>{{ item.studentName }}</strong
                    ><small>{{ item.studentCode }}</small>
                  </div>
                </div>
              </td>
              <td>
                <div class="course-cell">
                  <strong>{{ item.courseTitle }}</strong
                  ><small>{{ item.courseCode }}</small>
                </div>
              </td>
              <td>{{ formatDate(item.enrolledAt) }}</td>
              <td>
                <div class="progress-cell">
                  <div class="progress"><div class="progress-bar" :style="{ width: `${item.progress}%` }"></div></div>
                  <small>{{ item.progress }}%</small>
                </div>
              </td>
              <td>
                <strong>{{ item.finalScore ?? '—' }}</strong>
              </td>
              <td>
                <span :class="['badge', statusClass(item.status)]">{{ statusLabel(item.status) }}</span>
              </td>
              <td class="text-end">
                <button
                  v-if="item.status !== 'CANCELLED'"
                  class="btn btn-action-delete btn-sm"
                  title="Hủy ghi danh"
                  @click="cancelEnrollment(item)"
                >
                  <i class="bi bi-person-x"></i></button
                ><span v-else class="text-secondary small">Có thể ghi danh lại</span>
              </td>
            </tr>
            <tr v-if="!loading && !filteredItems.length">
              <td colspan="7" class="text-center text-secondary py-5">Chưa có dữ liệu ghi danh phù hợp.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-brand"></span></div>
    </div>

    <div v-if="formOpen" class="modal-mask" @click.self="formOpen = false">
      <form class="app-card enrollment-modal" @submit.prevent="saveEnrollment">
        <div class="modal-heading">
          <div>
            <small>GHI DANH KHÓA HỌC</small>
            <h2>Phân học viên vào khóa học</h2>
            <p>Chọn một khóa học và tích chọn một hoặc nhiều học viên.</p>
          </div>
          <button type="button" class="btn-close" aria-label="Đóng" @click="formOpen = false"></button>
        </div>

        <label class="form-label"><i class="bi bi-mortarboard me-1 text-brand"></i>Khóa học</label>
        <select v-model.number="form.courseId" class="form-select mb-3" required>
          <option :value="0" disabled>Chọn khóa học</option>
          <option v-for="course in courses" :key="course.id" :value="course.id">
            {{ course.code }} — {{ course.title }}
          </option>
        </select>

        <div class="picker-heading">
          <label class="form-label mb-0"
            ><i class="bi bi-people me-1 text-brand"></i>Học viên
            <span v-if="form.studentIds.length" class="selected-count"
              >Đã chọn {{ form.studentIds.length }}</span
            ></label
          >
          <button v-if="availableStudents.length" type="button" class="btn btn-link btn-sm" @click="toggleAllVisible">
            <i :class="['bi', allVisibleSelected ? 'bi-x-square' : 'bi-check2-square', 'me-1']"></i
            >{{ allVisibleSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả đang hiển thị' }}
          </button>
        </div>
        <div class="search-box mb-2">
          <i class="bi bi-search"></i
          ><input
            v-model.trim="studentSearch"
            class="form-control"
            placeholder="Tìm nhanh theo tên, mã hoặc email..."
          />
        </div>
        <div class="student-picker">
          <label
            v-for="student in availableStudents"
            :key="student.id"
            :class="['student-option', { selected: form.studentIds.includes(student.id) }]"
          >
            <input v-model="form.studentIds" type="checkbox" :value="student.id" />
            <span class="avatar">{{ initials(student.name) }}</span>
            <span
              ><strong>{{ student.name }}</strong
              ><small>{{ student.code }} · {{ student.email }}</small></span
            >
            <i class="bi bi-check-circle-fill"></i>
          </label>
          <div v-if="form.courseId && !availableStudents.length" class="empty-picker">
            Không còn học viên phù hợp. Học viên đã ghi danh sẽ không xuất hiện trong danh sách.
          </div>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="formOpen = false">
            <i class="bi bi-x-lg"></i> Hủy
          </button>
          <button class="btn btn-action-save" :disabled="saving || !form.courseId || !form.studentIds.length">
            <span v-if="saving" class="spinner-border spinner-border-sm me-1"></span
            ><i v-else class="bi bi-check-lg me-1"></i>Ghi danh {{ form.studentIds.length || '' }} học viên
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { useListViewState } from '../../composables/useListViewState'
import { confirmDialog } from '../../utils/confirmDialog'
import { statusLabel } from '../../utils/displayLabels'

const route = useRoute()
const items = ref([])
const students = ref([])
const courses = ref([])
const loading = ref(true)
const saving = ref(false)
const formOpen = ref(false)
const search = ref('')
const studentSearch = ref('')
const courseFilter = ref('')
const statusFilter = ref('')
const message = ref('')
const messageType = ref('success')
const form = reactive({ courseId: 0, studentIds: [] })
useListViewState('cms-enrollments', { search, courseFilter, statusFilter })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)

const activeItems = computed(() => items.value.filter((item) => item.status !== 'CANCELLED'))
const activeCount = computed(() => activeItems.value.length)
const completedCount = computed(() => items.value.filter((item) => item.status === 'COMPLETED').length)
const courseCount = computed(() => new Set(activeItems.value.map((item) => item.courseId)).size)
const filteredItems = computed(() => {
  const term = search.value.toLowerCase()
  return items.value.filter(
    (item) =>
      (!term ||
        `${item.studentName} ${item.studentCode} ${item.courseTitle} ${item.courseCode}`
          .toLowerCase()
          .includes(term)) &&
      (!courseFilter.value || item.courseId === Number(courseFilter.value)) &&
      (!statusFilter.value || item.status === statusFilter.value)
  )
})
const availableStudents = computed(() => {
  const term = studentSearch.value.toLowerCase()
  const enrolled = new Set(
    items.value
      .filter((item) => item.courseId === form.courseId && item.status !== 'CANCELLED')
      .map((item) => item.studentId)
  )
  return students.value.filter(
    (student) =>
      !enrolled.has(student.id) &&
      (!term || `${student.name} ${student.code} ${student.email}`.toLowerCase().includes(term))
  )
})
const allVisibleSelected = computed(
  () =>
    availableStudents.value.length > 0 &&
    availableStudents.value.every((student) => form.studentIds.includes(student.id))
)

watch(
  () => form.courseId,
  () => {
    form.studentIds = []
  }
)

onMounted(async () => {
  await Promise.all([loadEnrollments(), loadOptions()])
  const studentId = Number(route.query.studentId || 0)
  const student = students.value.find((item) => item.id === studentId)
  if (student) search.value = student.code || student.name
})

async function loadEnrollments() {
  loading.value = true
  try {
    const data = await axiosClient.get('/cms/enrollments', { params: { pageSize: 100, _fresh: Date.now() } })
    const rows = pick(data, 'items', 'Items') || []
    items.value = rows.map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      courseId: Number(pick(row, 'CourseId', 'courseId')),
      courseCode: pick(row, 'CourseCode', 'courseCode') || '',
      courseTitle: pick(row, 'CourseTitle', 'courseTitle') || '',
      studentId: Number(pick(row, 'StudentId', 'studentId')),
      studentCode: pick(row, 'StudentCode', 'studentCode') || '',
      studentName: pick(row, 'StudentName', 'studentName') || '',
      enrolledAt: pick(row, 'EnrolledAt', 'enrolledAt'),
      status: pick(row, 'Status', 'status') || 'ENROLLED',
      progress: Number(pick(row, 'ProgressPercent', 'progressPercent') || 0),
      finalScore: pick(row, 'FinalScore', 'finalScore')
    }))
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}

async function loadOptions() {
  try {
    const [studentData, courseData] = await Promise.all([
      axiosClient.get('/cms/students', { params: { status: 'ACTIVE', pageSize: 100, _fresh: Date.now() } }),
      axiosClient.get('/courses', { params: { pageSize: 100, _fresh: Date.now() } })
    ])
    students.value = (pick(studentData, 'items', 'Items') || []).map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      code: pick(row, 'StudentCode', 'studentCode') || '',
      name: pick(row, 'FullName', 'fullName') || '',
      email: pick(row, 'Email', 'email') || ''
    }))
    courses.value = (pick(courseData, 'items', 'Items') || []).map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      code: pick(row, 'Code', 'code') || '',
      title: pick(row, 'Title', 'title') || ''
    }))
  } catch (error) {
    show(error.message, 'danger')
  }
}

function openForm() {
  form.courseId = courses.value[0]?.id || 0
  form.studentIds = []
  studentSearch.value = ''
  formOpen.value = true
}

function toggleAllVisible() {
  const visibleIds = availableStudents.value.map((student) => student.id)
  if (allVisibleSelected.value) form.studentIds = form.studentIds.filter((id) => !visibleIds.includes(id))
  else form.studentIds = [...new Set([...form.studentIds, ...visibleIds])]
}

async function saveEnrollment() {
  saving.value = true
  const selectedIds = [...form.studentIds]
  let succeeded = 0
  const failed = []
  const failedIds = []
  try {
    for (const studentId of selectedIds) {
      try {
        await axiosClient.post('/cms/enrollments', { courseId: Number(form.courseId), studentId: Number(studentId) })
        succeeded++
      } catch (error) {
        const student = students.value.find((item) => item.id === studentId)
        failedIds.push(studentId)
        failed.push(`${student?.name || `ID ${studentId}`}: ${error.message}`)
      }
    }
    await loadEnrollments()
    if (!failed.length) {
      formOpen.value = false
      show(`Đã ghi danh thành công ${succeeded} học viên. Học viên có thể học khi khóa học được xuất bản.`)
    } else {
      form.studentIds = failedIds
      show(`Đã ghi danh ${succeeded}/${selectedIds.length} học viên. Chưa thành công: ${failed.join('; ')}`, 'danger')
    }
  } finally {
    saving.value = false
  }
}

async function cancelEnrollment(item) {
  const confirmed = await confirmDialog({
    title: 'Hủy ghi danh học viên',
    message: `Hủy ghi danh “${item.studentName}” khỏi khóa học “${item.courseTitle}”?`,
    confirmText: 'Hủy ghi danh',
    tone: 'warning',
    icon: 'bi-person-dash'
  })
  if (!confirmed) return
  try {
    await axiosClient.delete(`/cms/enrollments/${item.id}`)
    await loadEnrollments()
    show('Đã hủy ghi danh. Có thể ghi danh lại học viên này khi cần.')
  } catch (error) {
    show(error.message, 'danger')
  }
}

function initials(name = '') {
  return (
    name
      .split(' ')
      .filter(Boolean)
      .slice(-2)
      .map((value) => value[0])
      .join('')
      .toUpperCase() || 'HV'
  )
}
function formatDate(value) {
  return value
    ? new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(value))
    : '—'
}
function statusClass(value) {
  return (
    {
      ENROLLED: 'badge-soft-primary',
      IN_PROGRESS: 'badge-soft-warning',
      COMPLETED: 'badge-soft-success',
      CANCELLED: 'badge-soft-danger'
    }[value] || 'badge-soft-primary'
  )
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
}
</script>

<style scoped src="../../assets/css/pages/cms/enrollment-management.css"></style>
