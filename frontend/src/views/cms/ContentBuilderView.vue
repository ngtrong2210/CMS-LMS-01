<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title">Nội dung: {{ course.title }}</h1>
        <p class="page-subtitle mb-0">Thêm, sửa, xóa chương/bài học và chọn video dùng chung từ thư viện.</p>
      </div>
      <CmsPageActions>
        <RouterLink class="btn btn-action-view" to="/cms/videos"
          ><i class="bi bi-collection-play"></i> Thư viện video</RouterLink
        ><button class="btn btn-action-create" @click="openChapter()"><i class="bi bi-plus-lg"></i> Thêm chương</button>
      </CmsPageActions>
    </header>
    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>
    <div v-if="loading" class="app-card p-5 text-center"><span class="spinner-border text-success"></span></div>
    <div v-else class="builder">
      <article v-for="(chapter, index) in chapters" :key="chapter.id" class="app-card chapter-card">
        <header>
          <span class="number">{{ index + 1 }}</span>
          <div class="chapter-copy">
            <strong>{{ chapter.title }}</strong
            ><small
              >{{ chapter.lessons.length }} bài học • {{ chapter.status === 'ACTIVE' ? 'Hoạt động' : 'Tạm ẩn' }}</small
            >
          </div>
          <div class="ms-auto d-flex gap-2">
            <button class="btn btn-action-edit btn-sm" title="Sửa chương" @click="openChapter(chapter)">
              <i class="bi bi-pencil"></i></button
            ><button class="btn btn-action-delete btn-sm" title="Xóa chương" @click="askDelete('chapter', chapter)">
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </header>
        <div v-for="lesson in chapter.lessons" :key="lesson.id" class="lesson">
          <span class="type"
            ><i :class="['bi', lesson.lessonType.includes('VIDEO') ? 'bi-play-btn' : 'bi-file-earmark-text']"></i
          ></span>
          <div class="lesson-copy">
            <strong>{{ lesson.title }}</strong
            ><small
              >{{ lessonTypeLabel(lesson.lessonType) }} • {{ formatTime(lesson.durationSeconds)
              }}<template v-if="lesson.videoTitle"> • {{ lesson.videoTitle }}</template></small
            >
          </div>
          <span :class="['badge', lesson.status === 'ACTIVE' ? 'badge-soft-success' : 'badge-soft-warning']">{{
            lesson.status === 'ACTIVE' ? 'Hoạt động' : 'Tạm ẩn'
          }}</span>
          <div class="lesson-actions">
            <RouterLink
              v-if="lesson.videoId && lesson.canEditVideo"
              class="btn btn-action-view btn-sm"
              :to="`/cms/videos/${lesson.videoId}/editor`"
              title="Biên tập video mẫu"
              ><i class="bi bi-sliders"></i></RouterLink
            ><button
              v-if="lesson.lessonType.includes('VIDEO')"
              class="btn btn-blue btn-sm"
              :title="lesson.videoId ? 'Đổi video tham chiếu' : 'Chọn video từ thư viện'"
              @click="openVideoPicker(lesson)"
            >
              <i class="bi bi-collection-play"></i></button
            ><button class="btn btn-action-edit btn-sm" title="Sửa bài học" @click="openLesson(chapter, lesson)">
              <i class="bi bi-pencil"></i></button
            ><button class="btn btn-action-delete btn-sm" title="Xóa bài học" @click="askDelete('lesson', lesson)">
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </div>
        <div v-if="!chapter.lessons.length" class="empty-lessons">Chương này chưa có bài học.</div>
        <button class="add-lesson" @click="openLesson(chapter)"><i class="bi bi-plus-circle"></i> Thêm bài học</button>
      </article>
      <div v-if="!chapters.length" class="app-card empty-state">
        <i class="bi bi-journal-plus"></i>
        <h2>Chưa có chương</h2>
        <p>Tạo chương đầu tiên để bắt đầu xây dựng nội dung khóa học.</p>
        <button class="btn btn-action-create" @click="openChapter()"><i class="bi bi-plus-lg"></i> Thêm chương</button>
      </div>
    </div>

    <div v-if="chapterModal" class="modal-mask" @click.self="chapterModal = false">
      <form class="app-card form-modal" @submit.prevent="saveChapter">
        <div class="modal-heading">
          <div>
            <small>CHƯƠNG KHÓA HỌC</small>
            <h2>{{ chapterForm.id ? 'Sửa chương' : 'Thêm chương' }}</h2>
          </div>
          <button type="button" class="btn-close" @click="chapterModal = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label">Tên chương</label
            ><input v-model.trim="chapterForm.title" class="form-control" required maxlength="500" />
          </div>
          <div class="col-12">
            <label class="form-label">Mô tả</label
            ><textarea v-model.trim="chapterForm.description" class="form-control" rows="3"></textarea>
          </div>
          <div class="col-md-6">
            <label class="form-label">Thứ tự</label
            ><input v-model.number="chapterForm.sortOrder" class="form-control" type="number" min="1" required />
          </div>
          <div class="col-md-6">
            <label class="form-label">Trạng thái</label
            ><select v-model="chapterForm.status" class="form-select">
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="chapterModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu chương
          </button>
        </div>
      </form>
    </div>

    <div v-if="lessonModal" class="modal-mask" @click.self="lessonModal = false">
      <form class="app-card form-modal" @submit.prevent="saveLesson">
        <div class="modal-heading">
          <div>
            <small>BÀI HỌC</small>
            <h2>{{ lessonForm.id ? 'Sửa bài học' : 'Thêm bài học' }}</h2>
          </div>
          <button type="button" class="btn-close" @click="lessonModal = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label">Tên bài học</label
            ><input v-model.trim="lessonForm.title" class="form-control" required maxlength="500" />
          </div>
          <div class="col-12">
            <label class="form-label">Mô tả</label
            ><textarea v-model.trim="lessonForm.description" class="form-control" rows="3"></textarea>
          </div>
          <div class="col-md-6">
            <label class="form-label">Loại bài</label
            ><select v-model="lessonForm.lessonType" class="form-select">
              <option value="INTERACTIVE_VIDEO">Video tương tác</option>
              <option value="VIDEO">Video</option>
              <option value="QUIZ">Bài kiểm tra</option>
              <option value="DOCUMENT">Tài liệu</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label">Thứ tự</label
            ><input v-model.number="lessonForm.sortOrder" class="form-control" type="number" min="1" />
          </div>
          <div class="col-md-3">
            <label class="form-label">Điểm đạt</label
            ><input v-model.number="lessonForm.passingScore" class="form-control" type="number" min="0" max="100" />
          </div>
          <div class="col-md-6">
            <label class="form-label">Trạng thái</label
            ><select v-model="lessonForm.status" class="form-select">
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>
          <div class="col-md-6 check-row">
            <input id="requiredLesson" v-model="lessonForm.isRequired" class="form-check-input" type="checkbox" /><label
              for="requiredLesson"
              >Bài học bắt buộc</label
            >
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="lessonModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu bài học
          </button>
        </div>
      </form>
    </div>

    <div v-if="videoModal" class="modal-mask" @click.self="videoModal = false">
      <div class="app-card library-modal">
        <div class="modal-heading">
          <div>
            <small>VIDEO DÙNG CHUNG</small>
            <h2>Chọn video cho “{{ targetLesson?.title }}”</h2>
            <p>Một video thư viện có thể gắn vào nhiều môn và bài học.</p>
          </div>
          <button class="btn-close" @click="videoModal = false"></button>
        </div>
        <div class="library-toolbar">
          <input
            v-model.trim="videoSearch"
            class="form-control"
            placeholder="Tìm theo tên video hoặc tên file..."
          /><RouterLink class="btn btn-action-create text-nowrap" to="/cms/videos"
            ><i class="bi bi-plus-lg"></i> Thêm video mới</RouterLink
          >
        </div>
        <div class="video-list">
          <button
            v-for="asset in videoAssets"
            :key="asset.id"
            class="video-item"
            :disabled="saving"
            @click="attachVideo(asset)"
          >
            <span class="video-icon"><i class="bi bi-play-fill"></i></span>
            <div>
              <strong>{{ asset.title }}</strong
              ><small>{{ formatTime(asset.durationSeconds) }} • Đang dùng ở {{ asset.usageCount }} bài</small>
            </div>
            <span class="btn btn-blue btn-sm">Chọn</span>
          </button>
          <div v-if="!videoAssets.length" class="p-4 text-center text-secondary">Không tìm thấy video phù hợp.</div>
        </div>
      </div>
    </div>

    <div v-if="deleteTarget" class="modal-mask" @click.self="deleteTarget = null">
      <div class="app-card confirm-modal">
        <span class="delete-icon"><i class="bi bi-trash"></i></span>
        <h2>Xóa {{ deleteTarget.type === 'chapter' ? 'chương' : 'bài học' }}?</h2>
        <p>
          {{
            deleteTarget.type === 'chapter'
              ? 'Các bài học bên trong cũng sẽ bị ẩn khỏi hệ thống.'
              : 'Bài học sẽ bị ẩn khỏi khóa học và LMS.'
          }}
        </p>
        <div class="modal-actions">
          <button class="btn btn-action-cancel" @click="deleteTarget = null"><i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-delete" :disabled="saving" @click="removeTarget">
            <i class="bi bi-trash"></i> Xóa
          </button>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { formatInteractionTime } from '../../utils/learningRules'

const route = useRoute(),
  courseId = Number(route.params.id),
  course = reactive({ id: courseId, title: 'Khóa học' }),
  chapters = ref([]),
  loading = ref(true),
  saving = ref(false),
  message = ref(''),
  messageType = ref('success')
const chapterModal = ref(false),
  lessonModal = ref(false),
  videoModal = ref(false),
  deleteTarget = ref(null),
  targetLesson = ref(null),
  videoAssets = ref([]),
  videoSearch = ref('')
const chapterForm = reactive(blankChapter()),
  lessonForm = reactive(blankLesson())
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const formatTime = formatInteractionTime
let videoTimer
watch(videoSearch, () => {
  clearTimeout(videoTimer)
  videoTimer = setTimeout(loadVideoAssets, 250)
})
onMounted(load)

async function load() {
  loading.value = true
  try {
    const [courseData, content] = await Promise.all([
      axiosClient.get(`/courses/${courseId}`),
      axiosClient.get(`/courses/${courseId}/content`, { params: { _fresh: Date.now() } })
    ])
    course.title = pick(courseData, 'Title', 'title') || course.title
    const chapterRows = pick(content, 'chapters', 'Chapters') || [],
      lessonRows = pick(content, 'lessons', 'Lessons') || []
    chapters.value = chapterRows.map((row, index) => {
      const id = Number(pick(row, 'Id', 'id'))
      return {
        id,
        title: pick(row, 'Title', 'title'),
        description: pick(row, 'Description', 'description') || '',
        sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
        status: pick(row, 'Status', 'status') || 'ACTIVE',
        lessons: lessonRows.filter((x) => Number(pick(x, 'ChapterId', 'chapterId')) === id).map(mapLesson)
      }
    })
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
function mapLesson(row, index) {
  return {
    id: Number(pick(row, 'Id', 'id')),
    chapterId: Number(pick(row, 'ChapterId', 'chapterId')),
    title: pick(row, 'Title', 'title'),
    description: pick(row, 'Description', 'description') || '',
    lessonType: pick(row, 'LessonType', 'lessonType') || 'INTERACTIVE_VIDEO',
    durationSeconds: Number(pick(row, 'DurationSeconds', 'durationSeconds') || 0),
    sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
    isRequired: Boolean(pick(row, 'IsRequired', 'isRequired')),
    passingScore: Number(pick(row, 'PassingScore', 'passingScore') || 0),
    status: pick(row, 'Status', 'status') || 'ACTIVE',
    videoId: Number(pick(row, 'VideoId', 'videoId') || 0),
    videoAssetId: Number(pick(row, 'VideoAssetId', 'videoAssetId') || 0),
    videoTitle: pick(row, 'VideoTitle', 'videoTitle') || '',
    canEditVideo: Boolean(pick(row, 'CanEditVideo', 'canEditVideo'))
  }
}
function blankChapter() {
  return { id: 0, title: '', description: '', sortOrder: 1, status: 'ACTIVE' }
}
function blankLesson() {
  return {
    id: 0,
    chapterId: 0,
    title: '',
    description: '',
    lessonType: 'INTERACTIVE_VIDEO',
    durationSeconds: 0,
    sortOrder: 1,
    isRequired: true,
    passingScore: 0,
    status: 'ACTIVE'
  }
}
function openChapter(item = null) {
  Object.assign(
    chapterForm,
    item
      ? {
          id: item.id,
          title: item.title,
          description: item.description,
          sortOrder: item.sortOrder,
          status: item.status
        }
      : { ...blankChapter(), sortOrder: chapters.value.length + 1 }
  )
  chapterModal.value = true
}
function openLesson(chapter, item = null) {
  Object.assign(
    lessonForm,
    item ? { ...item } : { ...blankLesson(), chapterId: chapter.id, sortOrder: chapter.lessons.length + 1 }
  )
  lessonForm.chapterId = chapter.id
  lessonModal.value = true
}
async function saveChapter() {
  saving.value = true
  try {
    const body = {
      title: chapterForm.title,
      description: chapterForm.description || null,
      sortOrder: chapterForm.sortOrder,
      status: chapterForm.status
    }
    if (chapterForm.id) await axiosClient.put(`/chapters/${chapterForm.id}`, body)
    else await axiosClient.post(`/courses/${courseId}/chapters`, body)
    chapterModal.value = false
    await load()
    show('Đã lưu chương vào SQL.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function saveLesson() {
  saving.value = true
  try {
    const body = {
      title: lessonForm.title,
      description: lessonForm.description || null,
      lessonType: lessonForm.lessonType,
      durationSeconds: Math.max(0, Number(lessonForm.durationSeconds) || 0),
      sortOrder: lessonForm.sortOrder,
      isRequired: lessonForm.isRequired,
      passingScore: Number(lessonForm.passingScore) || 0,
      status: lessonForm.status
    }
    if (lessonForm.id) await axiosClient.put(`/lessons/${lessonForm.id}`, body)
    else await axiosClient.post(`/chapters/${lessonForm.chapterId}/lessons`, body)
    lessonModal.value = false
    await load()
    show('Đã lưu bài học vào SQL.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function askDelete(type, item) {
  deleteTarget.value = { type, item }
}
async function removeTarget() {
  saving.value = true
  try {
    await axiosClient.delete(
      `/${deleteTarget.value.type === 'chapter' ? 'chapters' : 'lessons'}/${deleteTarget.value.item.id}`
    )
    deleteTarget.value = null
    await load()
    show('Đã xóa nội dung khỏi khóa học.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function openVideoPicker(lesson) {
  targetLesson.value = lesson
  videoSearch.value = ''
  await loadVideoAssets()
  videoModal.value = true
}
async function loadVideoAssets() {
  try {
    const rows = await axiosClient.get('/video-library', {
      params: { search: videoSearch.value || undefined, _fresh: Date.now() }
    })
    videoAssets.value = (Array.isArray(rows) ? rows : [])
      .map((row) => ({
        id: Number(pick(row, 'Id', 'id')),
        videoId: Number(pick(row, 'VideoId', 'videoId') || pick(row, 'FirstVideoId', 'firstVideoId') || 0),
        title: pick(row, 'Title', 'title'),
        durationSeconds: Number(pick(row, 'DurationSeconds', 'durationSeconds') || 0),
        usageCount: Number(pick(row, 'UsageCount', 'usageCount') || 0)
      }))
      .filter((x) => x.videoId > 0)
  } catch (error) {
    show(error.message, 'danger')
  }
}
async function attachVideo(asset) {
  saving.value = true
  try {
    await axiosClient.put(`/lessons/${targetLesson.value.id}/video/${asset.videoId}`)
    videoModal.value = false
    await load()
    show(`Đã tham chiếu “${asset.title}” cho bài học. Không tạo bản sao video; kết quả học vẫn tách riêng theo bài.`)
    targetLesson.value = null
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function lessonTypeLabel(type) {
  return (
    { INTERACTIVE_VIDEO: 'Video tương tác', VIDEO: 'Video', QUIZ: 'Bài kiểm tra', DOCUMENT: 'Tài liệu' }[type] || type
  )
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped src="../../assets/css/pages/cms/content-builder.css"></style>
