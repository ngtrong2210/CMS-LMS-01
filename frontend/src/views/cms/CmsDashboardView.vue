<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title mb-1">Tổng quan hệ thống</h1>
        <p class="page-subtitle mb-0">Số liệu mới nhất được tổng hợp trực tiếp từ SQL Server.</p>
      </div>
      <CmsPageActions>
        <button class="btn btn-action-refresh" :disabled="loading" @click="load">
          <i class="bi bi-arrow-clockwise"></i> Làm mới
        </button>
      </CmsPageActions>
    </header>
    <div v-if="error" class="alert alert-danger">{{ error }}</div>
    <div class="row g-3 mb-4">
      <div v-for="stat in stats" :key="stat.label" class="col-6 col-xl-3">
        <div class="stat app-card">
          <div>
            <span>{{ stat.label }}</span
            ><strong>{{ stat.value }}</strong
            ><small>{{ stat.note }}</small>
          </div>
          <i :class="['bi', stat.icon, stat.tone]"></i>
        </div>
      </div>
    </div>
    <div class="row g-4">
      <div class="col-xl-8">
        <div class="app-card p-4 h-100">
          <div class="d-flex justify-content-between mb-3">
            <div>
              <h2 class="h5 fw-bold mb-1">Khóa học trong hệ thống</h2>
              <small class="text-secondary">Dữ liệu thật về bài học và học viên ghi danh</small>
            </div>
            <RouterLink class="small text-brand fw-bold" to="/cms/courses">Quản lý khóa học</RouterLink>
          </div>
          <div class="table-responsive">
            <table class="table align-middle mb-0">
              <thead>
                <tr>
                  <th>Khóa học</th>
                  <th>Giảng viên</th>
                  <th>Bài học</th>
                  <th>Học viên</th>
                  <th>Trạng thái</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in courses" :key="item.id">
                  <td>
                    <strong>{{ item.title }}</strong
                    ><small class="d-block text-secondary">{{ item.code }}</small>
                  </td>
                  <td>{{ item.teacherName }}</td>
                  <td>{{ item.lessonCount }}</td>
                  <td>{{ item.studentCount }}</td>
                  <td>
                    <span :class="['badge', courseStatusBadgeClass(item.status)]">{{ statusLabel(item.status) }}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <div class="col-xl-4">
        <div class="app-card p-4 mb-4">
          <h2 class="h5 fw-bold">Chất lượng học tập</h2>
          <div class="metric">
            <span>Tỷ lệ hoàn thành</span><strong>{{ dashboard.completionRate }}%</strong>
            <div class="progress">
              <div class="progress-bar" :style="{ width: dashboard.completionRate + '%' }"></div>
            </div>
          </div>
          <div class="metric">
            <span>Điểm trung bình</span><strong>{{ dashboard.averageScore }}</strong>
          </div>
        </div>
        <div class="app-card p-4">
          <h2 class="h5 fw-bold">Kho nội dung</h2>
          <div class="content-counts">
            <span
              ><i class="bi bi-play-btn"></i><strong>{{ dashboard.totalVideos }}</strong
              ><small>Video</small></span
            ><span
              ><i class="bi bi-patch-question"></i><strong>{{ dashboard.totalQuestions }}</strong
              ><small>Câu hỏi</small></span
            ><span
              ><i class="bi bi-person-video3"></i><strong>{{ dashboard.totalTeachers }}</strong
              ><small>Giảng viên</small></span
            >
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
import { courseStatusBadgeClass, statusLabel } from '../../utils/displayLabels'
const loading = ref(true),
  error = ref(''),
  courses = ref([]),
  dashboard = reactive({
    totalCourses: 0,
    totalStudents: 0,
    totalTeachers: 0,
    totalLessons: 0,
    totalVideos: 0,
    totalQuestions: 0,
    completionRate: 0,
    averageScore: 0
  })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const stats = computed(() => [
  {
    label: 'Tổng khóa học',
    value: dashboard.totalCourses,
    note: 'Trong cơ sở dữ liệu',
    icon: 'bi-journals',
    tone: 'green'
  },
  {
    label: 'Tổng học viên',
    value: dashboard.totalStudents,
    note: 'Tài khoản học viên',
    icon: 'bi-people',
    tone: 'blue'
  },
  {
    label: 'Tổng bài học',
    value: dashboard.totalLessons,
    note: 'Nội dung đang quản lý',
    icon: 'bi-list-task',
    tone: 'yellow'
  },
  { label: 'Điểm trung bình', value: dashboard.averageScore, note: 'Từ kết quả học tập', icon: 'bi-star', tone: 'red' }
])
onMounted(load)
async function load() {
  loading.value = true
  error.value = ''
  try {
    const [summary, list] = await Promise.all([
      axiosClient.get('/cms/dashboard', { params: { _fresh: Date.now() } }),
      axiosClient.get('/courses', { params: { pageSize: 6, _fresh: Date.now() } })
    ])
    for (const key of Object.keys(dashboard)) {
      const pascal = key[0].toUpperCase() + key.slice(1)
      dashboard[key] = Number(pick(summary, key, pascal) || 0)
    }
    const rows = pick(list, 'items', 'Items') || []
    courses.value = rows.map((row) => ({
      id: Number(pick(row, 'id', 'Id')),
      code: pick(row, 'code', 'Code'),
      title: pick(row, 'title', 'Title'),
      teacherName: pick(row, 'teacherName', 'TeacherName'),
      lessonCount: Number(pick(row, 'lessonCount', 'LessonCount') || 0),
      studentCount: Number(pick(row, 'studentCount', 'StudentCount') || 0),
      status: pick(row, 'status', 'Status')
    }))
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>
<style scoped src="../../assets/css/pages/cms/dashboard.css"></style>
