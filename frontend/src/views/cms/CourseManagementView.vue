<template>
  <section class="teaching-workspace-page">
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <span class="eyebrow">GIẢNG DẠY THEO NĂM HỌC</span>
        <h1 class="page-title mb-1">Soạn nội dung môn học lớp</h1>
        <p class="page-subtitle mb-0">
          Chọn đúng năm học, lớp và môn đã được phân công để xây dựng chương, bài học và bài tập.
        </p>
      </div>
      <CmsPageActions>
        <RouterLink class="btn btn-action-view" to="/cms/academic"
          ><i class="bi bi-diagram-3"></i> Cơ cấu đào tạo</RouterLink
        >
        <RouterLink class="btn btn-action-save" to="/cms/assignments"
          ><i class="bi bi-clipboard-check"></i> Chấm bài</RouterLink
        >
      </CmsPageActions>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="app-card workspace-filters">
      <label class="search-field"
        ><span>Tìm nhanh</span>
        <div class="input-icon">
          <i class="bi bi-search"></i
          ><input
            v-model.trim="filters.search"
            class="form-control"
            placeholder="Tên môn, lớp hoặc giảng viên..."
          /></div
      ></label>
      <label
        ><span>Năm học</span
        ><select v-model="filters.yearId" class="form-select">
          <option value="">Tất cả năm học</option>
          <option v-for="year in years" :key="year.yearId" :value="String(year.yearId)">{{ year.yearName }}</option>
        </select></label
      >
      <label
        ><span>Học kỳ</span
        ><select v-model="filters.semester" class="form-select">
          <option value="">Tất cả học kỳ</option>
          <option value="1">Học kỳ 1</option>
          <option value="2">Học kỳ 2</option>
          <option value="3">Học kỳ hè</option>
        </select></label
      >
      <label
        ><span>Trạng thái nội dung</span
        ><select v-model="filters.status" class="form-select">
          <option value="">Tất cả trạng thái</option>
          <option value="EMPTY">Chưa khởi tạo</option>
          <option value="DRAFT">Bản nháp</option>
          <option value="PUBLISHED">Đã xuất bản</option>
          <option value="ARCHIVED">Lưu trữ</option>
        </select></label
      >
    </div>

    <div class="app-card table-card">
      <div class="table-card-heading">
        <div>
          <strong>{{ filteredOfferings.length }} môn học lớp</strong
          ><small>Mỗi dòng là một môn của một lớp trong một năm học; không tạo khóa học rời.</small>
        </div>
      </div>
      <div class="table-responsive">
        <table class="table align-middle mb-0 workspace-table">
          <thead>
            <tr>
              <th>STT</th>
              <th>Năm học / Học kỳ</th>
              <th>Lớp / Môn học</th>
              <th>Giảng viên</th>
              <th>Nội dung</th>
              <th>Học viên</th>
              <th class="text-end action-cell">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in filteredOfferings" :key="item.classSubjectId">
              <td>{{ index + 1 }}</td>
              <td>
                <strong>{{ item.yearName }}</strong
                ><small>Học kỳ {{ item.semester }}</small>
              </td>
              <td>
                <div class="subject-cell">
                  <span class="subject-icon"><i class="bi bi-journal-bookmark-fill"></i></span>
                  <div>
                    <strong>{{ item.subjectName }}</strong
                    ><small>{{ item.className }} · {{ item.subjectId }}</small>
                  </div>
                </div>
              </td>
              <td>{{ item.teacherName || 'Chưa phân công' }}</td>
              <td>
                <template v-if="item.onlineCourseId"
                  ><span :class="['badge', courseStatusBadgeClass(item.onlineCourseStatus)]">{{
                    statusLabel(item.onlineCourseStatus)
                  }}</span
                  ><small>{{ item.chapterCount }} chương · {{ item.lessonCount }} bài</small></template
                >
                <template v-else
                  ><span class="badge badge-soft-warning">Chưa khởi tạo</span
                  ><small>Sẵn sàng tạo từ phân công</small></template
                >
              </td>
              <td>
                <strong>{{ item.studentCount }}</strong
                ><small>học viên của lớp</small>
              </td>
              <td class="text-end action-cell">
                <RouterLink
                  v-if="item.onlineCourseId"
                  class="btn btn-action-view btn-sm"
                  :to="`/cms/courses/${item.onlineCourseId}/content`"
                  ><i class="bi bi-pencil-square"></i> Soạn bài</RouterLink
                >
                <button v-if="item.onlineCourseId" class="btn btn-action-edit btn-sm ms-1" @click="openSettings(item)">
                  <i class="bi bi-sliders"></i> Thiết lập
                </button>
                <button
                  v-else
                  class="btn btn-action-create btn-sm"
                  :disabled="creatingId === item.classSubjectId || !item.teacherName"
                  @click="ensureWorkspace(item)"
                >
                  <span v-if="creatingId === item.classSubjectId" class="spinner-border spinner-border-sm"></span
                  ><i v-else class="bi bi-plus-circle"></i> Khởi tạo nội dung
                </button>
              </td>
            </tr>
            <tr v-if="!loading && !filteredOfferings.length">
              <td colspan="7" class="text-center text-secondary py-5">Không có môn học lớp phù hợp bộ lọc.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-brand"></span></div>
    </div>

    <div v-if="showSettings" class="modal-mask" @click.self="showSettings = false">
      <form class="app-card form-modal" @submit.prevent="saveSettings">
        <div class="modal-heading">
          <div>
            <small>Thiết lập môn học lớp</small>
            <h2>{{ settings.title }}</h2>
            <p>{{ settings.context }}</p>
          </div>
          <button type="button" class="btn-close" @click="showSettings = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label">Mô tả ngắn</label
            ><textarea v-model.trim="settings.shortDescription" class="form-control" rows="3"></textarea>
          </div>
          <div class="col-md-6">
            <label class="form-label">Điểm đạt toàn môn</label
            ><input v-model.number="settings.passingScore" class="form-control" type="number" min="0" max="100" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Trạng thái</label
            ><select v-model="settings.status" class="form-select">
              <option value="DRAFT">Bản nháp</option>
              <option value="PUBLISHED">Đã xuất bản</option>
              <option value="ARCHIVED">Lưu trữ</option>
            </select>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="showSettings = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu thiết lập
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
import { useListViewState } from '../../composables/useListViewState'
import { courseStatusBadgeClass, statusLabel } from '../../utils/displayLabels'

const years = ref([])
const offerings = ref([])
const loading = ref(true)
const saving = ref(false)
const creatingId = ref(0)
const showSettings = ref(false)
const message = ref('')
const messageType = ref('success')
const filters = reactive({ search: '', yearId: '', semester: '', status: '' })
const settings = reactive({
  id: 0,
  code: '',
  title: '',
  context: '',
  slug: '',
  shortDescription: '',
  description: '',
  teacherId: 0,
  categoryId: null,
  classSubjectId: null,
  level: 'BEGINNER',
  passingScore: 50,
  status: 'DRAFT'
})
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const searchState = computed({ get: () => filters.search, set: (value) => (filters.search = value) })
const yearState = computed({ get: () => filters.yearId, set: (value) => (filters.yearId = value) })
const semesterState = computed({ get: () => filters.semester, set: (value) => (filters.semester = value) })
const statusState = computed({ get: () => filters.status, set: (value) => (filters.status = value) })

useListViewState('cms-class-subject-workspaces', {
  search: searchState,
  yearId: yearState,
  semester: semesterState,
  status: statusState
})

const filteredOfferings = computed(() => {
  const term = filters.search.toLowerCase()
  return offerings.value.filter((item) => {
    const itemStatus = item.onlineCourseId ? item.onlineCourseStatus : 'EMPTY'
    return (
      (!filters.yearId || String(item.yearId) === filters.yearId) &&
      (!filters.semester || String(item.semester) === filters.semester) &&
      (!filters.status || itemStatus === filters.status) &&
      (!term ||
        `${item.subjectName} ${item.subjectId} ${item.className} ${item.teacherName}`.toLowerCase().includes(term))
    )
  })
})

onMounted(load)

async function load() {
  loading.value = true
  try {
    const data = await axiosClient.get('/academic/catalog', { params: { _fresh: Date.now() } })
    years.value = (pick(data, 'Years', 'years') || []).map((row) => ({
      yearId: Number(pick(row, 'YearID', 'yearID')),
      yearName: pick(row, 'YearName', 'yearName')
    }))
    offerings.value = (pick(data, 'ClassSubjects', 'classSubjects') || []).map(mapOffering)
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}

function mapOffering(row) {
  return {
    classSubjectId: Number(pick(row, 'ClassSubjectID', 'classSubjectID')),
    yearId: Number(pick(row, 'YearID', 'yearID')),
    yearName: pick(row, 'YearName', 'yearName'),
    semester: Number(pick(row, 'Semester', 'semester')),
    className: pick(row, 'ClassName', 'className'),
    subjectId: pick(row, 'SubjectID', 'subjectID'),
    subjectName: pick(row, 'SubjectName', 'subjectName'),
    teacherName: pick(row, 'TeacherName', 'teacherName') || '',
    onlineCourseId: Number(pick(row, 'OnlineCourseID', 'onlineCourseID') || 0),
    onlineCourseStatus: pick(row, 'OnlineCourseStatus', 'onlineCourseStatus') || '',
    chapterCount: Number(pick(row, 'ChapterCount', 'chapterCount') || 0),
    lessonCount: Number(pick(row, 'LessonCount', 'lessonCount') || 0),
    studentCount: Number(pick(row, 'StudentCount', 'studentCount') || 0)
  }
}

async function ensureWorkspace(item) {
  creatingId.value = item.classSubjectId
  try {
    await axiosClient.post(`/academic/class-subjects/${item.classSubjectId}/workspace`)
    await load()
    show(`Đã khởi tạo nội dung cho ${item.subjectName} · ${item.className}.`)
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    creatingId.value = 0
  }
}

async function openSettings(item) {
  try {
    const detail = await axiosClient.get(`/courses/${item.onlineCourseId}`)
    Object.assign(settings, {
      id: item.onlineCourseId,
      code: pick(detail, 'Code', 'code'),
      title: pick(detail, 'Title', 'title'),
      context: `${item.yearName} · Học kỳ ${item.semester} · ${item.className}`,
      slug: pick(detail, 'Slug', 'slug') || '',
      shortDescription: pick(detail, 'ShortDescription', 'shortDescription') || '',
      description: pick(detail, 'Description', 'description') || '',
      teacherId: Number(pick(detail, 'TeacherId', 'teacherId')),
      categoryId: Number(pick(detail, 'CategoryId', 'categoryId') || 0) || null,
      classSubjectId: item.classSubjectId,
      level: pick(detail, 'Level', 'level') || 'BEGINNER',
      passingScore: Number(pick(detail, 'PassingScore', 'passingScore') || 50),
      status: pick(detail, 'Status', 'status') || 'DRAFT'
    })
    showSettings.value = true
  } catch (error) {
    show(error.message, 'danger')
  }
}

async function saveSettings() {
  saving.value = true
  try {
    await axiosClient.put(`/courses/${settings.id}`, {
      code: settings.code,
      title: settings.title,
      slug: settings.slug,
      thumbnailUrl: null,
      shortDescription: settings.shortDescription || null,
      description: settings.description || null,
      teacherId: settings.teacherId,
      categoryId: settings.categoryId,
      classSubjectId: settings.classSubjectId,
      level: settings.level,
      passingScore: Number(settings.passingScore),
      status: settings.status
    })
    showSettings.value = false
    await load()
    show('Đã cập nhật thiết lập môn học lớp.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}

function show(text, type = 'success') {
  message.value = text
  messageType.value = type
}
</script>

<style scoped src="../../assets/css/pages/cms/course-management.css"></style>
