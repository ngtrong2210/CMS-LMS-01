<template>
  <section class="academic-page">
    <header class="academic-heading">
      <div>
        <span class="eyebrow">CƠ CẤU ĐÀO TẠO</span>
        <h1 class="page-title">Khóa · Khoa · Lớp · Môn học</h1>
        <p class="page-subtitle">Quản lý môn học lớp theo năm học và liên kết trực tiếp với nội dung LMS.</p>
      </div>
      <CmsPageActions v-if="isAdmin">
        <button class="btn btn-action-create" @click="openCreate('CLASS_SUBJECT')">
          <i class="bi bi-calendar2-plus"></i> Mở môn cho lớp
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="academic-flow app-card">
      <div v-for="(step, index) in flow" :key="step.label" class="flow-step">
        <span><i :class="['bi', step.icon]"></i></span>
        <div><small>BƯỚC {{ index + 1 }}</small><strong>{{ step.label }}</strong></div>
        <i v-if="index < flow.length - 1" class="bi bi-arrow-right flow-arrow"></i>
      </div>
    </div>

    <div class="academic-summary">
      <article v-for="card in summaryCards" :key="card.label" class="app-card summary-card">
        <span :class="['summary-icon', card.tone]"><i :class="['bi', card.icon]"></i></span>
        <div><strong>{{ card.value }}</strong><small>{{ card.label }}</small></div>
      </article>
    </div>

    <div class="app-card academic-toolbar">
      <div class="toolbar-title">
        <i class="bi bi-funnel"></i>
        <div><strong>Lọc môn học lớp</strong><small>Thu hẹp theo năm, học kỳ và lớp hành chính</small></div>
      </div>
      <label>
        <span>Năm học</span>
        <select v-model="filters.yearId" class="form-select">
          <option value="">Tất cả năm học</option>
          <option v-for="year in years" :key="year.yearId" :value="String(year.yearId)">{{ year.yearName }}</option>
        </select>
      </label>
      <label>
        <span>Học kỳ</span>
        <select v-model="filters.semester" class="form-select">
          <option value="">Tất cả học kỳ</option>
          <option value="1">Học kỳ 1</option>
          <option value="2">Học kỳ 2</option>
          <option value="3">Học kỳ hè</option>
        </select>
      </label>
      <label>
        <span>Lớp</span>
        <select v-model="filters.classId" class="form-select">
          <option value="">Tất cả lớp</option>
          <option v-for="item in classes" :key="item.classId" :value="item.classId">{{ item.className }}</option>
        </select>
      </label>
    </div>

    <nav class="academic-tabs" aria-label="Nhóm dữ liệu đào tạo">
      <button v-for="tab in tabs" :key="tab.key" :class="{ active: activeTab === tab.key }" @click="activeTab = tab.key">
        <i :class="['bi', tab.icon]"></i>{{ tab.label }}<span>{{ tab.count }}</span>
      </button>
    </nav>

    <div v-if="loading" class="app-card loading-card"><span class="spinner-border text-brand"></span></div>

    <div v-else-if="activeTab === 'offerings'" class="app-card table-card">
      <div class="table-card-heading">
        <div><strong>Môn học lớp đang mở</strong><small>Mỗi dòng là một môn của một lớp trong một năm và học kỳ.</small></div>
      </div>
      <div class="table-responsive">
        <table class="table align-middle academic-table">
          <thead><tr><th>STT</th><th>Năm / Học kỳ</th><th>Lớp</th><th>Môn học</th><th>Giảng viên</th><th>Nội dung LMS</th><th>Quy mô</th></tr></thead>
          <tbody>
            <tr v-for="(item, index) in filteredOfferings" :key="item.classSubjectId">
              <td>{{ index + 1 }}</td>
              <td><strong>{{ item.yearName }}</strong><small>Học kỳ {{ item.semester }}</small></td>
              <td><strong>{{ item.className }}</strong><small>{{ item.classId }}</small></td>
              <td><strong>{{ item.subjectName }}</strong><small>{{ item.subjectId }} · {{ item.creditCount }} tín chỉ</small></td>
              <td>{{ item.teacherName || 'Chưa phân công' }}</td>
              <td>
                <RouterLink v-if="item.onlineCourseId" class="course-link" :to="`/cms/courses/${item.onlineCourseId}/content`">
                  <i class="bi bi-box-arrow-up-right"></i><span><strong>{{ item.onlineCourseTitle }}</strong><small>{{ item.chapterCount }} chương · {{ item.lessonCount }} bài</small></span>
                </RouterLink>
                <span v-else class="badge badge-soft-warning">Chưa tạo nội dung</span>
              </td>
              <td><strong>{{ item.studentCount }} học viên</strong><small>{{ item.theoryQuantity }} LT · {{ item.practiceQuantity }} TH</small></td>
            </tr>
            <tr v-if="!filteredOfferings.length"><td colspan="7" class="empty-cell">Không có môn học lớp phù hợp bộ lọc.</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else-if="activeTab === 'timetable'" class="app-card table-card">
      <div class="table-card-heading timetable-heading">
        <div><strong>Thời khóa biểu</strong><small>Lịch học của từng môn học lớp trong năm học.</small></div>
        <button v-if="isAdmin" class="btn btn-action-create btn-sm" @click="openCreate('TIMETABLE')"><i class="bi bi-calendar2-plus"></i> Thêm lịch học</button>
      </div>
      <div class="table-responsive">
        <table class="table align-middle academic-table timetable-table">
          <thead><tr><th>STT</th><th>Thứ</th><th>Thời gian</th><th>Lớp / Môn học</th><th>Phòng</th><th>Hiệu lực</th><th v-if="isAdmin">Thao tác</th></tr></thead>
          <tbody>
            <tr v-for="(item, index) in filteredTimetables" :key="item.timetableId">
              <td>{{ index + 1 }}</td>
              <td><span class="day-badge">{{ dayLabel(item.dayOfWeek) }}</span></td>
              <td><strong>{{ timeText(item.startTime) }} – {{ timeText(item.endTime) }}</strong><small>Tiết {{ item.startPeriod || '—' }} – {{ item.endPeriod || '—' }}</small></td>
              <td><strong>{{ item.subjectName }}</strong><small>{{ item.className }} · {{ item.yearName }} · HK{{ item.semester }}</small></td>
              <td>{{ item.roomName || 'Chưa xếp phòng' }}</td>
              <td>{{ dateText(item.effectiveFrom) }} – {{ dateText(item.effectiveTo) }}</td>
              <td v-if="isAdmin"><button class="btn btn-action-view btn-sm" @click="openTimetable(item)"><i class="bi bi-pencil-square"></i> Sửa lịch</button></td>
            </tr>
            <tr v-if="!filteredTimetables.length"><td :colspan="isAdmin ? 7 : 6" class="empty-cell">Không có lịch học phù hợp bộ lọc.</td></tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else-if="activeTab === 'classes'" class="catalog-grid">
      <article v-for="item in classes" :key="item.classId" class="app-card catalog-card">
        <header><span class="catalog-icon blue"><i class="bi bi-people"></i></span><span class="status-dot"></span></header>
        <strong>{{ item.className }}</strong><small>{{ item.classId }} · {{ item.scienceName }}</small>
        <dl><div><dt>Khóa</dt><dd>{{ item.courseName }}</dd></div><div><dt>Sĩ số</dt><dd>{{ item.studentCount }}/{{ item.classSize }}</dd></div></dl>
        <button v-if="isAdmin" class="btn btn-action-view btn-sm" @click="openAssign(item)"><i class="bi bi-person-check"></i> Phân học viên</button>
      </article>
      <button v-if="isAdmin" class="app-card catalog-add" @click="openCreate('CLASS')"><i class="bi bi-plus-circle"></i><span>Thêm lớp hành chính</span></button>
    </div>

    <div v-else-if="activeTab === 'subjects'" class="catalog-grid">
      <article v-for="item in subjects" :key="item.subjectId" class="app-card catalog-card">
        <header><span class="catalog-icon green"><i class="bi bi-book"></i></span><span class="credit-badge">{{ item.creditCount }} TC</span></header>
        <strong>{{ item.subjectName }}</strong><small>{{ item.subjectId }} · {{ item.scienceName }}</small>
        <dl><div><dt>Lý thuyết</dt><dd>{{ item.theoryQuantity }} tiết</dd></div><div><dt>Thực hành</dt><dd>{{ item.practiceQuantity }} tiết</dd></div></dl>
      </article>
      <button v-if="isAdmin" class="app-card catalog-add" @click="openCreate('SUBJECT')"><i class="bi bi-plus-circle"></i><span>Thêm môn học</span></button>
    </div>

    <div v-else-if="activeTab === 'students'" class="app-card table-card">
      <div class="table-responsive">
        <table class="table align-middle academic-table">
          <thead><tr><th>STT</th><th>Học viên</th><th>Mã sinh viên</th><th>Lớp</th><th>Liên hệ</th><th>Trạng thái</th></tr></thead>
          <tbody><tr v-for="(item, index) in students" :key="item.studentId"><td>{{ index + 1 }}</td><td><strong>{{ item.fullName }}</strong></td><td>{{ item.studentId }}</td><td>{{ item.className }}</td><td><span>{{ item.email || '—' }}</span><small>{{ item.mobile || '' }}</small></td><td><span class="badge badge-soft-success">Đang học</span></td></tr></tbody>
        </table>
      </div>
    </div>

    <div v-else class="catalog-sections">
      <section class="app-card mini-catalog"><header><div><strong>Năm học</strong><small>Chu kỳ tổ chức đào tạo</small></div><button v-if="isAdmin" @click="openCreate('YEAR')"><i class="bi bi-plus"></i></button></header><div v-for="item in years" :key="item.yearId"><span><i class="bi bi-calendar3"></i>{{ item.yearName }}</span><small>{{ dateText(item.startAt) }} – {{ dateText(item.finishAt) }}</small></div></section>
      <section class="app-card mini-catalog"><header><div><strong>Khoa</strong><small>Đơn vị chuyên môn</small></div><button v-if="isAdmin" @click="openCreate('SCIENCE')"><i class="bi bi-plus"></i></button></header><div v-for="item in sciences" :key="item.scienceId"><span><i class="bi bi-building"></i>{{ item.scienceName }}</span><small>{{ item.scienceId }}</small></div></section>
      <section class="app-card mini-catalog"><header><div><strong>Khóa tuyển sinh</strong><small>K18, K19...</small></div><button v-if="isAdmin" @click="openCreate('COHORT')"><i class="bi bi-plus"></i></button></header><div v-for="item in cohorts" :key="item.courseId"><span><i class="bi bi-mortarboard"></i>{{ item.courseName }}</span><small>{{ item.startYear }} – {{ item.finishYear }}</small></div></section>
    </div>

    <div v-if="formModal" class="modal-mask" @click.self="formModal = false">
      <form class="app-card academic-modal" @submit.prevent="saveCatalog">
        <div class="modal-heading"><div><small>DANH MỤC ĐÀO TẠO</small><h2>{{ formTitle }}</h2></div><button type="button" class="btn-close" @click="formModal = false"></button></div>
        <div class="row g-3">
          <template v-if="!['CLASS_SUBJECT','TIMETABLE'].includes(form.entityType)">
            <div class="col-md-5"><label class="form-label">Mã</label><input v-model.trim="form.code" class="form-control" required /></div>
            <div class="col-md-7"><label class="form-label">Tên hiển thị</label><input v-model.trim="form.name" class="form-control" required /></div>
          </template>
          <div v-if="['SUBJECT','CLASS'].includes(form.entityType)" class="col-md-6"><label class="form-label">Khoa</label><select v-model="form.parentCode" class="form-select" required><option value="">Chọn khoa</option><option v-for="item in sciences" :key="item.scienceId" :value="item.scienceId">{{ item.scienceName }}</option></select></div>
          <div v-if="form.entityType === 'CLASS'" class="col-md-6"><label class="form-label">Khóa tuyển sinh</label><select v-model="form.subjectId" class="form-select" required><option value="">Chọn khóa</option><option v-for="item in cohorts" :key="item.courseId" :value="item.courseId">{{ item.courseName }}</option></select></div>
          <div v-if="form.entityType === 'YEAR'" class="col-md-6"><label class="form-label">Bắt đầu</label><input v-model="form.startAt" class="form-control" type="date" /></div>
          <div v-if="form.entityType === 'YEAR'" class="col-md-6"><label class="form-label">Kết thúc</label><input v-model="form.finishAt" class="form-control" type="date" /></div>
          <div v-if="form.entityType === 'COHORT'" class="col-md-6"><label class="form-label">Năm bắt đầu</label><input v-model.number="form.startYear" class="form-control" type="number" required /></div>
          <div v-if="form.entityType === 'COHORT'" class="col-md-6"><label class="form-label">Năm kết thúc</label><input v-model.number="form.finishYear" class="form-control" type="number" required /></div>
          <template v-if="form.entityType === 'SUBJECT'"><div class="col-md-4"><label class="form-label">Tín chỉ</label><input v-model.number="form.creditCount" class="form-control" type="number" min="0" /></div><div class="col-md-4"><label class="form-label">Tiết lý thuyết</label><input v-model.number="form.theoryQuantity" class="form-control" type="number" min="0" /></div><div class="col-md-4"><label class="form-label">Tiết thực hành</label><input v-model.number="form.practiceQuantity" class="form-control" type="number" min="0" /></div></template>
          <template v-if="form.entityType === 'CLASS_SUBJECT'"><div class="col-md-6"><label class="form-label">Năm học</label><select v-model.number="form.yearId" class="form-select" required><option :value="null">Chọn năm</option><option v-for="item in years" :key="item.yearId" :value="item.yearId">{{ item.yearName }}</option></select></div><div class="col-md-6"><label class="form-label">Học kỳ</label><select v-model.number="form.semester" class="form-select" required><option :value="null">Chọn học kỳ</option><option :value="1">Học kỳ 1</option><option :value="2">Học kỳ 2</option><option :value="3">Học kỳ hè</option></select></div><div class="col-md-6"><label class="form-label">Lớp</label><select v-model="form.classId" class="form-select" required><option value="">Chọn lớp</option><option v-for="item in classes" :key="item.classId" :value="item.classId">{{ item.className }}</option></select></div><div class="col-md-6"><label class="form-label">Môn học</label><select v-model="form.subjectId" class="form-select" required><option value="">Chọn môn</option><option v-for="item in subjects" :key="item.subjectId" :value="item.subjectId">{{ item.subjectName }}</option></select></div><div class="col-12"><label class="form-label">Giảng viên</label><select v-model="form.teacherId" class="form-select"><option value="">Chưa phân công</option><option v-for="item in teachers" :key="item.teacherId" :value="item.teacherId">{{ item.teacherName }}</option></select></div></template>
          <template v-if="form.entityType === 'TIMETABLE'"><div class="col-12"><label class="form-label">Môn học lớp</label><select v-model.number="form.classSubjectId" class="form-select" required><option :value="null">Chọn môn học lớp</option><option v-for="item in offerings" :key="item.classSubjectId" :value="item.classSubjectId">{{ item.className }} · {{ item.subjectName }} · {{ item.yearName }} HK{{ item.semester }}</option></select></div><div class="col-md-4"><label class="form-label">Thứ</label><select v-model.number="form.dayOfWeek" class="form-select" required><option :value="null">Chọn thứ</option><option v-for="day in weekDays" :key="day.value" :value="day.value">{{ day.label }}</option></select></div><div class="col-md-4"><label class="form-label">Tiết bắt đầu</label><input v-model.number="form.startPeriod" class="form-control" type="number" min="1" max="30" /></div><div class="col-md-4"><label class="form-label">Tiết kết thúc</label><input v-model.number="form.endPeriod" class="form-control" type="number" min="1" max="30" /></div><div class="col-md-4"><label class="form-label">Giờ bắt đầu</label><input v-model="form.startTime" class="form-control" type="time" /></div><div class="col-md-4"><label class="form-label">Giờ kết thúc</label><input v-model="form.endTime" class="form-control" type="time" /></div><div class="col-md-4"><label class="form-label">Phòng học</label><input v-model.trim="form.roomName" class="form-control" placeholder="Ví dụ: LAB.02" /></div><div class="col-md-6"><label class="form-label">Hiệu lực từ ngày</label><input v-model="form.effectiveFrom" class="form-control" type="date" /></div><div class="col-md-6"><label class="form-label">Hiệu lực đến ngày</label><input v-model="form.effectiveTo" class="form-control" type="date" /></div></template>
        </div>
        <div class="modal-actions"><button type="button" class="btn btn-action-cancel" @click="formModal = false"><i class="bi bi-x-lg"></i> Hủy</button><button class="btn btn-action-save" :disabled="saving"><span v-if="saving" class="spinner-border spinner-border-sm"></span><i v-else class="bi bi-check-lg"></i> Lưu danh mục</button></div>
      </form>
    </div>

    <div v-if="assignModal" class="modal-mask" @click.self="assignModal = false">
      <form class="app-card academic-modal assign-modal" @submit.prevent="assignStudents">
        <div class="modal-heading"><div><small>PHÂN HỌC VIÊN</small><h2>{{ assignTarget?.className }}</h2><p>Chọn nhiều học viên; hệ thống tự ghi danh các môn LMS của lớp.</p></div><button type="button" class="btn-close" @click="assignModal = false"></button></div>
        <label class="search-students"><i class="bi bi-search"></i><input v-model.trim="studentSearch" placeholder="Tìm theo tên hoặc mã sinh viên..." /></label>
        <div class="student-select-list"><label v-for="item in assignableStudents" :key="item.userId" :class="{ selected: selectedStudents.includes(item.userId) }"><input v-model="selectedStudents" type="checkbox" :value="item.userId" /><span><strong>{{ item.fullName }}</strong><small>{{ item.studentId }} · {{ item.className }}</small></span></label></div>
        <div class="modal-actions"><span class="selection-count">Đã chọn {{ selectedStudents.length }} học viên</span><button type="button" class="btn btn-action-cancel" @click="assignModal = false">Hủy</button><button class="btn btn-action-save" :disabled="saving || !selectedStudents.length"><i class="bi bi-person-check"></i> Phân vào lớp</button></div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
import CmsPageActions from '../../components/navigation/CmsPageActions.vue'
import { useAuthStore } from '../../stores/authStore'

const auth = useAuthStore()
const isAdmin = computed(() => auth.user?.role === 'ADMIN')
const loading = ref(true)
const saving = ref(false)
const message = ref('')
const messageType = ref('success')
const activeTab = ref('offerings')
const formModal = ref(false)
const assignModal = ref(false)
const assignTarget = ref(null)
const studentSearch = ref('')
const selectedStudents = ref([])
const summary = reactive({})
const years = ref([])
const sciences = ref([])
const cohorts = ref([])
const classes = ref([])
const subjects = ref([])
const teachers = ref([])
const students = ref([])
const offerings = ref([])
const timetables = ref([])
const filters = reactive({ yearId: '', semester: '', classId: '' })
const form = reactive(blankForm())
const pick = (source, ...names) => names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const flow = [
  { label: 'Khóa tuyển sinh', icon: 'bi-mortarboard' },
  { label: 'Khoa chuyên môn', icon: 'bi-building' },
  { label: 'Lớp hành chính', icon: 'bi-people' },
  { label: 'Môn học lớp theo năm', icon: 'bi-calendar2-week' },
  { label: 'Chương và bài học LMS', icon: 'bi-journal-richtext' }
]
const weekDays = [
  { value: 2, label: 'Thứ Hai' },
  { value: 3, label: 'Thứ Ba' },
  { value: 4, label: 'Thứ Tư' },
  { value: 5, label: 'Thứ Năm' },
  { value: 6, label: 'Thứ Sáu' },
  { value: 7, label: 'Thứ Bảy' },
  { value: 8, label: 'Chủ nhật' }
]
const summaryCards = computed(() => [
  { label: 'Năm học', value: summary.yearCount || 0, icon: 'bi-calendar3', tone: 'blue' },
  { label: 'Lớp hành chính', value: summary.classCount || 0, icon: 'bi-people', tone: 'green' },
  { label: 'Môn học', value: summary.subjectCount || 0, icon: 'bi-book', tone: 'orange' },
  { label: 'Môn học lớp', value: summary.classSubjectCount || 0, icon: 'bi-calendar2-week', tone: 'pink' },
  { label: 'Học viên', value: summary.studentCount || 0, icon: 'bi-person-badge', tone: 'navy' }
])
const tabs = computed(() => [
  { key: 'offerings', label: 'Môn học lớp', icon: 'bi-calendar2-week', count: offerings.value.length },
  { key: 'timetable', label: 'Thời khóa biểu', icon: 'bi-clock-history', count: timetables.value.length },
  { key: 'classes', label: 'Lớp', icon: 'bi-people', count: classes.value.length },
  { key: 'subjects', label: 'Môn học', icon: 'bi-book', count: subjects.value.length },
  { key: 'students', label: 'Học viên', icon: 'bi-person-badge', count: students.value.length },
  { key: 'catalog', label: 'Danh mục gốc', icon: 'bi-diagram-3', count: years.value.length + sciences.value.length + cohorts.value.length }
])
const filteredOfferings = computed(() => offerings.value.filter((item) =>
  (!filters.yearId || String(item.yearId) === filters.yearId) &&
  (!filters.semester || String(item.semester) === filters.semester) &&
  (!filters.classId || item.classId === filters.classId)
))
const filteredTimetables = computed(() => timetables.value.filter((item) =>
  (!filters.yearId || String(item.yearId) === filters.yearId) &&
  (!filters.semester || String(item.semester) === filters.semester) &&
  (!filters.classId || item.classId === filters.classId)
))
const assignableStudents = computed(() => {
  const term = studentSearch.value.toLowerCase()
  return students.value.filter((item) => !term || `${item.fullName} ${item.studentId}`.toLowerCase().includes(term))
})
const formTitle = computed(() => ({ YEAR: 'Thêm năm học', SCIENCE: 'Thêm khoa', COHORT: 'Thêm khóa tuyển sinh', SUBJECT: 'Thêm môn học', CLASS: 'Thêm lớp hành chính', CLASS_SUBJECT: 'Mở môn học cho lớp', TIMETABLE: form.timetableId ? 'Cập nhật lịch học' : 'Thêm lịch học' })[form.entityType])

onMounted(load)

function mapRows(rows, mapping) {
  return (rows || []).map((row) => Object.fromEntries(Object.entries(mapping).map(([key, names]) => [key, pick(row, ...names)])))
}
async function load() {
  loading.value = true
  try {
    const data = await axiosClient.get('/academic/catalog', { params: { _fresh: Date.now() } })
    Object.assign(summary, pick(data, 'Summary', 'summary') || {})
    years.value = mapRows(pick(data, 'Years', 'years'), { dataGroupId: ['DataGroupID','dataGroupID'], yearId: ['YearID','yearID'], yearName: ['YearName','yearName'], startAt: ['StartAt','startAt'], finishAt: ['FinishAt','finishAt'] })
    sciences.value = mapRows(pick(data, 'Sciences', 'sciences'), { scienceId: ['ScienceID','scienceID'], scienceName: ['ScienceName','scienceName'], scienceShortName: ['ScienceShortName','scienceShortName'] })
    cohorts.value = mapRows(pick(data, 'Cohorts', 'cohorts'), { courseId: ['CourseID','courseID'], courseName: ['CourseName','courseName'], startYear: ['StartYear','startYear'], finishYear: ['FinishYear','finishYear'] })
    classes.value = mapRows(pick(data, 'Classes', 'classes'), { classId: ['ClassID','classID'], className: ['ClassName','className'], scienceName: ['ScienceName','scienceName'], courseName: ['CourseName','courseName'], classSize: ['ClassSize','classSize'], studentCount: ['StudentCount','studentCount'] })
    subjects.value = mapRows(pick(data, 'Subjects', 'subjects'), { subjectId: ['SubjectID','subjectID'], subjectName: ['SubjectName','subjectName'], scienceName: ['ScienceName','scienceName'], theoryQuantity: ['TheoryQuantity','theoryQuantity'], practiceQuantity: ['PracticeQuantity','practiceQuantity'], creditCount: ['CreditCount','creditCount'] })
    teachers.value = mapRows(pick(data, 'Teachers', 'teachers'), { teacherId: ['TeacherID','teacherID'], userId: ['UserID','userID'], teacherName: ['TeacherName','teacherName'] })
    students.value = mapRows(pick(data, 'Students', 'students'), { studentId: ['StudentID','studentID'], userId: ['UserID','userID'], fullName: ['FullName','fullName'], classId: ['ClassID','classID'], className: ['ClassName','className'], email: ['Email','email'], mobile: ['Mobile','mobile'] })
    offerings.value = mapRows(pick(data, 'ClassSubjects', 'classSubjects'), { classSubjectId: ['ClassSubjectID','classSubjectID'], yearId: ['YearID','yearID'], yearName: ['YearName','yearName'], semester: ['Semester','semester'], classId: ['ClassID','classID'], className: ['ClassName','className'], subjectId: ['SubjectID','subjectID'], subjectName: ['SubjectName','subjectName'], teacherName: ['TeacherName','teacherName'], creditCount: ['CreditCount','creditCount'], theoryQuantity: ['TheoryQuantity','theoryQuantity'], practiceQuantity: ['PracticeQuantity','practiceQuantity'], onlineCourseId: ['OnlineCourseID','onlineCourseID'], onlineCourseTitle: ['OnlineCourseTitle','onlineCourseTitle'], chapterCount: ['ChapterCount','chapterCount'], lessonCount: ['LessonCount','lessonCount'], studentCount: ['StudentCount','studentCount'] })
    timetables.value = mapRows(pick(data, 'Timetables', 'timetables'), { timetableId: ['TimetableID','timetableID'], classSubjectId: ['ClassSubjectID','classSubjectID'], yearId: ['YearID','yearID'], yearName: ['YearName','yearName'], semester: ['Semester','semester'], classId: ['ClassID','classID'], className: ['ClassName','className'], subjectId: ['SubjectID','subjectID'], subjectName: ['SubjectName','subjectName'], dayOfWeek: ['DayOfWeek','dayOfWeek'], startPeriod: ['StartPeriod','startPeriod'], endPeriod: ['EndPeriod','endPeriod'], startTime: ['StartTime','startTime'], endTime: ['EndTime','endTime'], roomName: ['RoomName','roomName'], effectiveFrom: ['EffectiveFrom','effectiveFrom'], effectiveTo: ['EffectiveTo','effectiveTo'] })
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
function blankForm() {
  return { entityType: 'CLASS_SUBJECT', dataGroupId: 1, code: '', name: '', shortName: '', parentCode: '', startYear: new Date().getFullYear(), finishYear: new Date().getFullYear() + 4, startAt: '', finishAt: '', yearId: null, semester: null, classSubjectId: null, classId: '', subjectId: '', teacherId: '', classSize: 40, creditCount: 3, theoryQuantity: 30, practiceQuantity: 30, timetableId: null, dayOfWeek: null, startPeriod: 1, endPeriod: 3, startTime: '07:00', endTime: '09:30', roomName: '', effectiveFrom: '', effectiveTo: '' }
}
function openCreate(entityType) {
  Object.assign(form, blankForm(), { entityType })
  formModal.value = true
}
function openTimetable(item) {
  Object.assign(form, blankForm(), {
    entityType: 'TIMETABLE',
    timetableId: item.timetableId,
    classSubjectId: item.classSubjectId,
    dayOfWeek: item.dayOfWeek,
    startPeriod: item.startPeriod,
    endPeriod: item.endPeriod,
    startTime: timeText(item.startTime),
    endTime: timeText(item.endTime),
    roomName: item.roomName || '',
    effectiveFrom: item.effectiveFrom?.slice(0, 10) || '',
    effectiveTo: item.effectiveTo?.slice(0, 10) || ''
  })
  formModal.value = true
}
async function saveCatalog() {
  saving.value = true
  try {
    await axiosClient.post('/academic/catalog', {
      ...form,
      startAt: form.startAt || null,
      finishAt: form.finishAt || null,
      teacherId: form.teacherId || null,
      startTime: form.startTime ? `${form.startTime}:00` : null,
      endTime: form.endTime ? `${form.endTime}:00` : null,
      effectiveFrom: form.effectiveFrom || null,
      effectiveTo: form.effectiveTo || null
    })
    formModal.value = false
    await load()
    show('Đã lưu cấu trúc đào tạo.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function openAssign(item) {
  assignTarget.value = item
  selectedStudents.value = students.value.filter((student) => student.classId === item.classId).map((student) => student.userId)
  studentSearch.value = ''
  assignModal.value = true
}
async function assignStudents() {
  saving.value = true
  try {
    await axiosClient.post('/academic/classes/students', { dataGroupId: 1, classId: assignTarget.value.classId, studentUserIds: selectedStudents.value })
    assignModal.value = false
    await load()
    show('Đã phân học viên vào lớp và tự ghi danh các môn LMS của lớp.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function dateText(value) {
  return value ? new Intl.DateTimeFormat('vi-VN').format(new Date(value)) : '—'
}
function dayLabel(value) {
  return weekDays.find((item) => item.value === Number(value))?.label || '—'
}
function timeText(value) {
  return value ? String(value).slice(0, 5) : '—'
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped src="../../assets/css/pages/cms/academic-structure.css"></style>
<style scoped src="../../assets/css/pages/cms/academic-timetable.css"></style>
