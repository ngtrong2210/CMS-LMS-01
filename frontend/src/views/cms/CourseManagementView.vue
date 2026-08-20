<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title mb-1">Quản lý khóa học</h1>
        <p class="page-subtitle mb-0">Tạo, cập nhật và quản lý nội dung đào tạo từ SQL Server.</p>
      </div>
      <CmsPageActions>
        <button class="btn btn-action-create" @click="openForm()">
          <i class="bi bi-plus-lg me-1"></i> Thêm khóa học
        </button>
      </CmsPageActions>
    </header>
    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>
    <div class="app-card p-3 mb-3">
      <div class="row g-2">
        <div class="col-md-8">
          <input v-model.trim="search" class="form-control" placeholder="Tìm kiếm tên hoặc mã khóa học..." />
        </div>
        <div class="col-md-4">
          <select v-model="status" class="form-select">
            <option value="">Tất cả trạng thái</option>
            <option value="PUBLISHED">Đã xuất bản</option>
            <option value="DRAFT">Bản nháp</option>
            <option value="ARCHIVED">Lưu trữ</option>
          </select>
        </div>
      </div>
    </div>
    <div class="app-card p-2">
      <div class="table-responsive">
        <table class="table align-middle mb-0">
          <thead>
            <tr>
              <th>Khóa học</th>
              <th>Giảng viên</th>
              <th>Học viên</th>
              <th>Bài học</th>
              <th>Trạng thái</th>
              <th class="text-end">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="course in items" :key="course.id">
              <td>
                <div class="d-flex align-items-center gap-2">
                  <span class="course-thumb"><i class="bi bi-code-slash"></i></span>
                  <div>
                    <strong>{{ course.title }}</strong
                    ><small class="d-block text-secondary">{{ course.code }} • {{ course.level }}</small>
                  </div>
                </div>
              </td>
              <td>{{ course.teacherName }}</td>
              <td>{{ course.studentCount }}</td>
              <td>{{ course.lessonCount }}</td>
              <td>
                <span :class="['badge', courseStatusBadgeClass(course.status)]">{{ statusLabel(course.status) }}</span>
              </td>
              <td class="text-end text-nowrap">
                <RouterLink
                  class="btn btn-action-view btn-sm me-1"
                  :to="`/cms/courses/${course.id}/content`"
                  title="Nội dung"
                  ><i class="bi bi-list-task"></i></RouterLink
                ><button class="btn btn-action-edit btn-sm me-1" title="Sửa" @click="openForm(course)">
                  <i class="bi bi-pencil"></i></button
                ><button class="btn btn-action-delete btn-sm" title="Xóa" @click="remove(course)">
                  <i class="bi bi-trash"></i>
                </button>
              </td>
            </tr>
            <tr v-if="!loading && !items.length">
              <td colspan="6" class="text-center text-secondary py-5">Không tìm thấy khóa học.</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-success"></span></div>
    </div>
    <div v-if="showForm" class="modal-mask" @click.self="showForm = false">
      <form class="app-card form-modal" @submit.prevent="save">
        <div class="d-flex justify-content-between">
          <div>
            <small class="text-brand fw-bold">KHÓA HỌC</small>
            <h2 class="h4 fw-bold">{{ form.id ? 'Sửa khóa học' : 'Thêm khóa học' }}</h2>
          </div>
          <button type="button" class="btn-close" @click="showForm = false"></button>
        </div>
        <div class="row g-3 mt-1">
          <div class="col-md-4">
            <label class="form-label">Mã khóa học</label
            ><input v-model.trim="form.code" class="form-control" required maxlength="100" />
          </div>
          <div class="col-md-8">
            <label class="form-label">Tên khóa học</label
            ><input v-model.trim="form.title" class="form-control" required maxlength="500" />
          </div>
          <div class="col-12">
            <label class="form-label">Mô tả ngắn</label
            ><textarea v-model.trim="form.shortDescription" class="form-control" rows="3"></textarea>
          </div>
          <div class="col-md-4">
            <label class="form-label">ID giảng viên</label
            ><input v-model.number="form.teacherId" class="form-control" type="number" min="1" required />
          </div>
          <div class="col-md-4">
            <label class="form-label">ID danh mục</label
            ><input v-model.number="form.categoryId" class="form-control" type="number" min="1" />
          </div>
          <div class="col-md-4">
            <label class="form-label">Trình độ</label
            ><select v-model="form.level" class="form-select">
              <option value="BEGINNER">Cơ bản</option>
              <option value="INTERMEDIATE">Trung cấp</option>
              <option value="ADVANCED">Nâng cao</option>
            </select>
          </div>
          <div class="col-12">
            <label class="form-label"><i class="bi bi-diagram-3"></i> Môn học lớp theo năm học</label>
            <select v-model.number="form.classSubjectId" class="form-select">
              <option :value="null">Không liên kết môn học lớp</option>
              <option v-for="item in academicOfferings" :key="item.classSubjectId" :value="item.classSubjectId">
                {{ item.yearName }} · HK{{ item.semester }} · {{ item.className }} · {{ item.subjectName }}
              </option>
            </select>
            <small class="form-text">Liên kết giúp học viên trong lớp được tự động ghi danh đúng môn.</small>
          </div>
          <div class="col-md-6">
            <label class="form-label">Điểm đạt</label
            ><input v-model.number="form.passingScore" class="form-control" type="number" min="0" max="100" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Trạng thái</label
            ><select v-model="form.status" class="form-select">
              <option value="DRAFT">Bản nháp</option>
              <option value="PUBLISHED">Đã xuất bản</option>
              <option value="ARCHIVED">Lưu trữ</option>
            </select>
          </div>
        </div>
        <div class="d-flex justify-content-end gap-2 mt-4">
          <button type="button" class="btn btn-action-cancel" @click="showForm = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu khóa học
          </button>
        </div>
      </form>
    </div>
  </section>
</template>
<script setup>
import { onMounted, reactive, ref, watch } from 'vue'
import axiosClient from '../../api/axiosClient'
import { useListViewState } from '../../composables/useListViewState'
import { confirmDialog } from '../../utils/confirmDialog'
import { courseStatusBadgeClass, statusLabel } from '../../utils/displayLabels'
const items = ref([]),
  academicOfferings = ref([]),
  search = ref(''),
  status = ref(''),
  loading = ref(true),
  saving = ref(false),
  showForm = ref(false),
  message = ref(''),
  messageType = ref('success'),
  form = reactive(blank())
useListViewState('cms-courses', { search, status })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
let timer
watch([search, status], () => {
  clearTimeout(timer)
  timer = setTimeout(load, 250)
})
onMounted(() => Promise.all([load(), loadAcademicOptions()]))
function blank() {
  return {
    id: 0,
    code: '',
    title: '',
    slug: '',
    shortDescription: '',
    description: '',
    teacherId: 2,
    categoryId: 1,
    classSubjectId: null,
    level: 'BEGINNER',
    passingScore: 60,
    status: 'DRAFT'
  }
}
async function loadAcademicOptions() {
  try {
    const data = await axiosClient.get('/academic/catalog')
    const rows = pick(data, 'ClassSubjects', 'classSubjects') || []
    academicOfferings.value = rows.map((row) => ({
      classSubjectId: Number(pick(row, 'ClassSubjectID', 'classSubjectID')),
      yearName: pick(row, 'YearName', 'yearName'),
      semester: Number(pick(row, 'Semester', 'semester')),
      className: pick(row, 'ClassName', 'className'),
      subjectName: pick(row, 'SubjectName', 'subjectName')
    }))
  } catch {
    academicOfferings.value = []
  }
}
async function load() {
  loading.value = true
  try {
    const data = await axiosClient.get('/courses', {
      params: {
        search: search.value || undefined,
        status: status.value || undefined,
        pageSize: 100,
        _fresh: Date.now()
      }
    })
    const rows = pick(data, 'items', 'Items') || []
    items.value = rows.map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      code: pick(row, 'Code', 'code'),
      title: pick(row, 'Title', 'title'),
      slug: pick(row, 'Slug', 'slug'),
      shortDescription: pick(row, 'ShortDescription', 'shortDescription') || '',
      teacherName: pick(row, 'TeacherName', 'teacherName'),
      teacherId: Number(pick(row, 'TeacherId', 'teacherId') || 0),
      categoryId: Number(pick(row, 'CategoryId', 'categoryId') || 0),
      level: pick(row, 'Level', 'level'),
      passingScore: Number(pick(row, 'PassingScore', 'passingScore') || 0),
      lessonCount: Number(pick(row, 'LessonCount', 'lessonCount') || 0),
      studentCount: Number(pick(row, 'StudentCount', 'studentCount') || 0),
      status: pick(row, 'Status', 'status')
    }))
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
async function openForm(item = null) {
  Object.assign(form, blank())
  if (item) {
    try {
      const detail = await axiosClient.get(`/courses/${item.id}`)
      Object.assign(form, {
        id: item.id,
        code: pick(detail, 'Code', 'code'),
        title: pick(detail, 'Title', 'title'),
        slug: pick(detail, 'Slug', 'slug') || '',
        shortDescription: pick(detail, 'ShortDescription', 'shortDescription') || '',
        description: pick(detail, 'Description', 'description') || '',
        teacherId: Number(pick(detail, 'TeacherId', 'teacherId')),
        categoryId: Number(pick(detail, 'CategoryId', 'categoryId') || 0) || null,
        classSubjectId: Number(pick(detail, 'ClassSubjectID', 'classSubjectID') || 0) || null,
        level: pick(detail, 'Level', 'level'),
        passingScore: Number(pick(detail, 'PassingScore', 'passingScore') || 0),
        status: pick(detail, 'Status', 'status')
      })
    } catch (error) {
      show(error.message, 'danger')
      return
    }
  }
  showForm.value = true
}
async function save() {
  saving.value = true
  try {
    const body = {
      code: form.code,
      title: form.title,
      slug: form.slug || form.code.toLowerCase(),
      thumbnailUrl: null,
      shortDescription: form.shortDescription || null,
      description: form.description || null,
      teacherId: Number(form.teacherId),
      categoryId: form.categoryId ? Number(form.categoryId) : null,
      classSubjectId: form.classSubjectId ? Number(form.classSubjectId) : null,
      level: form.level,
      passingScore: Number(form.passingScore) || 0,
      status: form.status
    }
    if (form.id) await axiosClient.put(`/courses/${form.id}`, body)
    else await axiosClient.post('/courses', body)
    showForm.value = false
    await load()
    show('Đã lưu khóa học.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function remove(item) {
  const confirmed = await confirmDialog({
    title: 'Xóa khóa học',
    message: `Bạn có chắc muốn xóa khóa học “${item.title}”?`,
    confirmText: 'Xóa khóa học',
    tone: 'danger',
    icon: 'bi-trash3'
  })
  if (!confirmed) return
  try {
    await axiosClient.delete(`/courses/${item.id}`)
    await load()
    show('Đã xóa khóa học.')
  } catch (error) {
    show(error.message, 'danger')
  }
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
}
</script>
<style scoped src="../../assets/css/pages/cms/course-management.css"></style>
