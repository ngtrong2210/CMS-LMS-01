<template>
  <section class="grading-page">
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <span class="grading-eyebrow">BÀI TẬP MÔN HỌC LỚP</span>
        <h1 class="page-title mb-1">Chấm và trả bài</h1>
        <p class="page-subtitle mb-0">Theo dõi bài nộp, xem lịch sử, nhập điểm và phản hồi cho học viên.</p>
      </div>
      <CmsPageActions
        ><RouterLink class="btn btn-action-view" to="/cms/courses"
          ><i class="bi bi-journal-text"></i> Soạn môn học lớp</RouterLink
        ></CmsPageActions
      >
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="grading-summary">
      <article v-for="card in summaryCards" :key="card.label" class="app-card">
        <span :class="card.tone"><i :class="['bi', card.icon]"></i></span>
        <div>
          <strong>{{ card.value }}</strong
          ><small>{{ card.label }}</small>
        </div>
      </article>
    </div>

    <div class="app-card grading-filters">
      <label class="grading-search"
        ><span>Tìm học viên hoặc bài tập</span>
        <div>
          <i class="bi bi-search"></i
          ><input
            v-model.trim="filters.search"
            class="form-control"
            placeholder="Mã sinh viên, họ tên, tên bài tập..."
          /></div
      ></label>
      <label
        ><span>Môn học lớp</span
        ><select v-model="filters.classSubjectId" class="form-select">
          <option value="">Tất cả môn học lớp</option>
          <option v-for="item in classSubjects" :key="item.id" :value="String(item.id)">{{ item.label }}</option>
        </select></label
      >
      <label
        ><span>Trạng thái</span
        ><select v-model="filters.status" class="form-select">
          <option value="">Tất cả trạng thái</option>
          <option value="SUBMITTED">Chờ chấm</option>
          <option value="GRADED">Đã chấm</option>
          <option value="RETURNED">Đã trả bổ sung</option>
          <option value="DRAFT">Bản nháp</option>
        </select></label
      >
    </div>

    <div class="app-card grading-table-card">
      <div class="table-responsive">
        <table class="table align-middle mb-0 grading-table">
          <thead>
            <tr>
              <th>STT</th>
              <th>Học viên</th>
              <th>Môn học lớp</th>
              <th>Bài tập</th>
              <th>Lần nộp</th>
              <th>Thời gian</th>
              <th>Trạng thái</th>
              <th>Điểm</th>
              <th class="text-end">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in submissions" :key="item.id">
              <td>{{ index + 1 }}</td>
              <td>
                <strong>{{ item.studentName }}</strong
                ><small>{{ item.studentCode || `User #${item.studentUserId}` }} · {{ item.className }}</small>
              </td>
              <td>
                <strong>{{ item.subjectName }}</strong
                ><small>{{ item.yearName }} · HK{{ item.semester }}</small>
              </td>
              <td>
                <strong>{{ item.lessonTitle }}</strong
                ><small>{{ item.chapterTitle }}</small>
              </td>
              <td>Lần {{ item.attemptNumber }}</td>
              <td>
                <strong>{{ dateTimeText(item.submittedAt) }}</strong
                ><small v-if="item.isLate" class="late-text">Nộp trễ</small>
              </td>
              <td>
                <span :class="['badge', statusClass(item.status)]">{{ submissionStatus(item.status) }}</span>
              </td>
              <td>
                <strong>{{ item.score == null ? '—' : `${item.score}/${item.maxScore}` }}</strong>
              </td>
              <td class="text-end">
                <button class="btn btn-action-edit btn-sm" @click="openSubmission(item)">
                  <i class="bi bi-clipboard-check"></i> {{ item.status === 'GRADED' ? 'Xem / sửa điểm' : 'Chấm bài' }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && !submissions.length">
              <td colspan="9" class="text-center text-secondary py-5">Chưa có bài nộp phù hợp.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-brand"></span></div>
    </div>

    <div v-if="selected" class="modal-mask" @click.self="selected = null">
      <form class="app-card grading-modal" @submit.prevent="grade('GRADE')">
        <div class="modal-heading">
          <div>
            <small>Chấm bài · Lần {{ selected.attemptNumber }}</small>
            <h2>{{ selected.lessonTitle }}</h2>
            <p>{{ selected.studentName }} · {{ selected.studentCode }} · {{ selected.className }}</p>
          </div>
          <button type="button" class="btn-close" @click="selected = null"></button>
        </div>
        <div class="submission-context">
          <div>
            <span>Môn học lớp</span
            ><strong>{{ selected.subjectName }} · {{ selected.yearName }} · HK{{ selected.semester }}</strong>
          </div>
          <div>
            <span>Thời gian nộp</span><strong>{{ dateTimeText(selected.submittedAt) }}</strong>
          </div>
        </div>
        <div class="submission-content">
          <h3>Nội dung học viên nộp</h3>
          <p>{{ selected.submissionText || 'Học viên không nhập nội dung ghi chú.' }}</p>
          <a
            v-if="selected.fileUrl"
            class="btn btn-action-view btn-sm"
            :href="resolveApiAssetUrl(selected.fileUrl)"
            target="_blank"
            rel="noopener"
            ><i class="bi bi-download"></i> Tải {{ selected.fileName || 'file bài làm' }}</a
          >
        </div>
        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label">Điểm (tối đa {{ selected.maxScore }})</label
            ><input
              v-model.number="gradeForm.score"
              class="form-control"
              type="number"
              min="0"
              :max="selected.maxScore"
              step="0.25"
              required
            />
          </div>
          <div class="col-md-8">
            <label class="form-label">Nhận xét của giảng viên</label
            ><textarea
              v-model.trim="gradeForm.feedback"
              class="form-control"
              rows="4"
              placeholder="Nêu rõ phần đạt và phần cần bổ sung..."
            ></textarea>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="selected = null">
            <i class="bi bi-x-lg"></i> Đóng</button
          ><button type="button" class="btn btn-action-delete" :disabled="saving" @click="grade('RETURN')">
            <i class="bi bi-arrow-return-left"></i> Trả bổ sung</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu điểm
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { useListViewState } from '../../composables/useListViewState'

const loading = ref(true)
const saving = ref(false)
const submissions = ref([])
const classSubjects = ref([])
const selected = ref(null)
const message = ref('')
const messageType = ref('success')
const filters = reactive({ search: '', classSubjectId: '', status: '' })
const gradeForm = reactive({ score: null, feedback: '' })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const searchState = computed({ get: () => filters.search, set: (value) => (filters.search = value) })
const classSubjectState = computed({
  get: () => filters.classSubjectId,
  set: (value) => (filters.classSubjectId = value)
})
const statusState = computed({ get: () => filters.status, set: (value) => (filters.status = value) })
useListViewState('cms-assignment-grading', {
  search: searchState,
  classSubjectId: classSubjectState,
  status: statusState
})

const summaryCards = computed(() => [
  { label: 'Tổng bài nộp', value: submissions.value.length, icon: 'bi-inbox', tone: 'blue' },
  {
    label: 'Chờ chấm',
    value: submissions.value.filter((x) => x.status === 'SUBMITTED').length,
    icon: 'bi-hourglass-split',
    tone: 'orange'
  },
  {
    label: 'Đã chấm',
    value: submissions.value.filter((x) => x.status === 'GRADED').length,
    icon: 'bi-check2-circle',
    tone: 'green'
  },
  { label: 'Nộp trễ', value: submissions.value.filter((x) => x.isLate).length, icon: 'bi-clock-history', tone: 'red' }
])

let timer
watch(
  filters,
  () => {
    clearTimeout(timer)
    timer = setTimeout(loadSubmissions, 250)
  },
  { deep: true }
)
onMounted(async () => {
  await loadClassSubjects()
  await loadSubmissions()
})

async function loadClassSubjects() {
  try {
    const data = await axiosClient.get('/academic/catalog')
    classSubjects.value = (pick(data, 'ClassSubjects', 'classSubjects') || [])
      .filter((row) => pick(row, 'OnlineCourseID', 'onlineCourseID'))
      .map((row) => ({
        id: Number(pick(row, 'ClassSubjectID', 'classSubjectID')),
        label: `${pick(row, 'SubjectName', 'subjectName')} · ${pick(row, 'ClassName', 'className')} · ${pick(row, 'YearName', 'yearName')} · HK${pick(row, 'Semester', 'semester')}`
      }))
  } catch (error) {
    show(error.message, 'danger')
  }
}

async function loadSubmissions() {
  loading.value = true
  try {
    const rows = await axiosClient.get('/teaching/assignment-submissions', {
      params: {
        classSubjectId: filters.classSubjectId || undefined,
        status: filters.status || undefined,
        search: filters.search || undefined,
        _fresh: Date.now()
      }
    })
    submissions.value = (Array.isArray(rows) ? rows : []).map(mapSubmission)
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}

function mapSubmission(row) {
  return {
    id: Number(pick(row, 'AssignmentSubmissionID', 'assignmentSubmissionID')),
    studentUserId: Number(pick(row, 'StudentUserID', 'studentUserID')),
    studentCode: pick(row, 'StudentCode', 'studentCode') || '',
    studentName: pick(row, 'StudentName', 'studentName') || '',
    className: pick(row, 'ClassName', 'className') || '',
    subjectName: pick(row, 'SubjectName', 'subjectName') || '',
    yearName: pick(row, 'YearName', 'yearName') || '',
    semester: Number(pick(row, 'Semester', 'semester') || 0),
    chapterTitle: pick(row, 'ChapterTitle', 'chapterTitle') || '',
    lessonTitle: pick(row, 'LessonTitle', 'lessonTitle') || '',
    attemptNumber: Number(pick(row, 'AttemptNumber', 'attemptNumber') || 1),
    submittedAt: pick(row, 'SubmittedAt', 'submittedAt'),
    status: pick(row, 'SubmissionStatus', 'submissionStatus'),
    score: pick(row, 'Score', 'score'),
    maxScore: Number(pick(row, 'AssignmentMaxScore', 'assignmentMaxScore') || 100),
    feedback: pick(row, 'Feedback', 'feedback') || '',
    isLate: Boolean(pick(row, 'IsLate', 'isLate')),
    submissionText: pick(row, 'SubmissionText', 'submissionText') || '',
    fileUrl: pick(row, 'FileUrl', 'fileUrl') || '',
    fileName: pick(row, 'OriginalFileName', 'originalFileName') || ''
  }
}

function openSubmission(item) {
  selected.value = item
  gradeForm.score = item.score == null ? null : Number(item.score)
  gradeForm.feedback = item.feedback
}

async function grade(action) {
  if (
    action === 'GRADE' &&
    (gradeForm.score == null || gradeForm.score < 0 || gradeForm.score > selected.value.maxScore)
  ) {
    show(`Điểm phải từ 0 đến ${selected.value.maxScore}.`, 'danger')
    return
  }
  saving.value = true
  try {
    await axiosClient.put(`/teaching/assignment-submissions/${selected.value.id}/grade`, {
      score: action === 'GRADE' ? Number(gradeForm.score) : null,
      feedback: gradeForm.feedback || null,
      action
    })
    selected.value = null
    await loadSubmissions()
    show(action === 'GRADE' ? 'Đã lưu điểm và nhận xét.' : 'Đã trả bài để học viên bổ sung.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}

function submissionStatus(value) {
  return { DRAFT: 'Bản nháp', SUBMITTED: 'Chờ chấm', GRADED: 'Đã chấm', RETURNED: 'Trả bổ sung' }[value] || value
}
function statusClass(value) {
  return (
    {
      DRAFT: 'badge-soft-warning',
      SUBMITTED: 'badge-soft-primary',
      GRADED: 'badge-soft-success',
      RETURNED: 'badge-soft-danger'
    }[value] || 'badge-soft-warning'
  )
}
function dateTimeText(value) {
  return value
    ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
    : '—'
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
}
</script>

<style scoped src="../../assets/css/pages/cms/assignment-grading.css"></style>
