<template>
  <section>
    <div v-if="loading" class="app-card p-5 text-center"><span class="spinner-border text-success"></span></div>
    <div v-else-if="error" class="alert alert-danger">
      {{ error }}
      <button class="btn btn-action-refresh btn-sm ms-2" @click="loadDashboard">
        <i class="bi bi-arrow-clockwise"></i> Thử lại
      </button>
    </div>
    <template v-else
      ><div class="welcome app-card mb-4">
        <div>
          <span class="welcome-label">HỌC TẬP MỖI NGÀY</span>
          <h1>Xin chào, {{ summary.fullName }} 👋</h1>
          <p>Tiếp tục hành trình học tập và hoàn thành mục tiêu hôm nay.</p>
          <RouterLink
            v-if="courses[0]"
            class="btn btn-brand"
            :to="`/lms/courses/${courses[0].id}/lessons/${courses[0].continueLessonId}`"
            >Tiếp tục học <i class="bi bi-arrow-right ms-1"></i
          ></RouterLink>
        </div>
        <div class="goal">
          <span class="goal-ring">{{ Math.round(courses[0]?.progress || 0) }}<small>%</small></span>
          <div>
            <strong>Tiến độ gần nhất</strong><small>{{ courses[0]?.title || 'Chưa có khóa học' }}</small>
          </div>
        </div>
      </div>
      <div class="row g-3 mb-4">
        <div v-for="stat in stats" :key="stat.label" class="col-6 col-lg-3">
          <div class="stat app-card">
            <span :class="['stat-icon', stat.tone]"><i :class="['bi', stat.icon]"></i></span>
            <div>
              <strong>{{ stat.value }}</strong
              ><small>{{ stat.label }}</small>
            </div>
          </div>
        </div>
      </div>
      <div class="d-flex justify-content-between align-items-end mb-3">
        <div>
          <h2 class="h4 fw-bold mb-1">Tiếp tục học</h2>
          <span class="page-subtitle">Khóa học bạn truy cập gần đây</span>
        </div>
        <RouterLink class="text-brand fw-semibold small" to="/lms/courses"
          >Xem tất cả <i class="bi bi-arrow-right"></i
        ></RouterLink>
      </div>
      <div v-if="courses.length" class="row g-4">
        <div v-for="course in courses.slice(0, 2)" :key="course.id" class="col-lg-6">
          <article class="course app-card">
            <div class="course-cover">
              <i class="bi bi-code-slash"></i><span>{{ course.code }}</span>
            </div>
            <div class="p-3 flex-grow-1">
              <span class="badge badge-soft-success mb-2">{{ course.category }}</span>
              <h3>{{ course.title }}</h3>
              <div class="small text-secondary mb-3"><i class="bi bi-person me-1"></i>{{ course.teacher }}</div>
              <div class="d-flex justify-content-between small mb-1">
                <span>Tiến độ</span><b>{{ course.progress }}%</b>
              </div>
              <div class="progress course-progress mb-3">
                <div class="progress-bar" :style="{ width: course.progress + '%' }"></div>
              </div>
              <RouterLink class="btn btn-action-view btn-sm" :to="`/lms/courses/${course.id}`"
                ><i class="bi bi-arrow-right-circle"></i> Mở khóa học</RouterLink
              >
            </div>
          </article>
        </div>
      </div>
      <div v-else class="app-card p-5 text-center text-secondary">
        Bạn chưa được ghi danh vào khóa học nào.
      </div></template
    >
  </section>
</template>
<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
const loading = ref(true),
  error = ref(''),
  courses = ref([]),
  summary = reactive({
    fullName: 'Học viên',
    activeCourses: 0,
    completedLessons: 0,
    averageScore: 0,
    learningSeconds: 0
  }),
  pick = (s, ...n) => n.map((x) => s?.[x]).find((v) => v !== undefined && v !== null)
const stats = computed(() => [
  { label: 'Khóa học đang học', value: summary.activeCourses, icon: 'bi-journal-play', tone: 'green' },
  { label: 'Bài học hoàn thành', value: summary.completedLessons, icon: 'bi-check2-circle', tone: 'blue' },
  { label: 'Điểm trung bình', value: summary.averageScore, icon: 'bi-star', tone: 'yellow' },
  { label: 'Thời gian học', value: `${Math.round(summary.learningSeconds / 360) / 10}h`, icon: 'bi-clock', tone: 'red' }
])
onMounted(loadDashboard)
async function loadDashboard() {
  loading.value = true
  error.value = ''
  try {
    const data = await axiosClient.get('/lms/dashboard', { params: { _fresh: Date.now() } }),
      s = pick(data, 'summary', 'Summary') || {}
    Object.assign(summary, {
      fullName: pick(s, 'FullName', 'fullName') || 'Học viên',
      activeCourses: Number(pick(s, 'ActiveCourseCount', 'activeCourseCount') || 0),
      completedLessons: Number(pick(s, 'CompletedLessonCount', 'completedLessonCount') || 0),
      averageScore: Number(pick(s, 'AverageScore', 'averageScore') || 0),
      learningSeconds: Number(pick(s, 'LearningSeconds', 'learningSeconds') || 0)
    })
    courses.value = (pick(data, 'courses', 'Courses') || []).map((r) => ({
      id: Number(pick(r, 'Id', 'id')),
      code: pick(r, 'Code', 'code'),
      title: pick(r, 'Title', 'title'),
      teacher: pick(r, 'TeacherName', 'teacherName'),
      category: pick(r, 'CategoryName', 'categoryName') || 'Khóa học',
      progress: Number(pick(r, 'ProgressPercent', 'progressPercent') || 0),
      continueLessonId: Number(pick(r, 'ContinueLessonId', 'continueLessonId') || 0)
    }))
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
</script>
<style scoped src="../../assets/css/pages/lms/dashboard.css"></style>
