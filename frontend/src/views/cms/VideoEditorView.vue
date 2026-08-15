<template>
  <section>
    <header class="video-editor-header d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
      <div>
        <h1 class="page-title video-editor-title mb-1">Biên tập video tương tác</h1>
        <p class="page-subtitle mb-0">{{ form.title }} • Thời lượng {{ formatTime(form.durationSeconds) }}</p>
      </div>
      <div class="video-header-actions d-flex flex-wrap gap-2">
        <button class="btn header-preview-button" :disabled="previewLoading" @click="openPreview">
          <span v-if="previewLoading" class="spinner-border spinner-border-sm me-1"></span
          ><i v-else class="bi bi-eye"></i> Xem như học viên
        </button>
        <label class="btn header-upload-button mb-0" :class="{ disabled: uploading }"
          ><i class="bi bi-cloud-arrow-up"></i> {{ uploading ? `Đang tải ${uploadProgress}%` : 'Upload video'
          }}<input
            class="visually-hidden"
            type="file"
            accept="video/mp4,video/webm,video/ogg,video/quicktime"
            :disabled="uploading"
            @change="uploadVideo"
        /></label>
        <button class="btn btn-brand" :disabled="saving || !form.lessonId" @click="saveVideo">
          <span v-if="saving" class="spinner-border spinner-border-sm me-1"></span
          ><i v-else class="bi bi-check-lg"></i> Lưu video
        </button>
      </div>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      <i :class="['bi', messageType === 'danger' ? 'bi-exclamation-circle' : 'bi-check-circle', 'me-2']"></i
      >{{ message }}
    </div>

    <div class="editor-grid">
      <div class="app-card video-card">
        <div class="video">
          <video
            v-if="playbackUrl"
            ref="videoRef"
            :src="playbackUrl"
            :poster="form.posterUrl || undefined"
            controls
            preload="metadata"
            @timeupdate="syncTime"
            @loadedmetadata="syncMetadata"
          ></video>
          <div v-else class="video-empty">
            <i class="bi bi-cloud-arrow-up"></i><strong>Chưa có video trong project</strong
            ><span>Chọn file MP4, WebM, OGV hoặc MOV để upload.</span>
          </div>
        </div>
        <div class="video-toolbar">
          <div class="current-position">
            <small>Vị trí hiện tại</small><strong>{{ formatTime(currentTime) }}</strong>
          </div>
          <div v-if="uploadedFile" class="file-meta">
            <i class="bi bi-file-earmark-play"></i>
            <div>
              <strong>{{ uploadedFile.originalFileName }}</strong
              ><small>{{ formatBytes(uploadedFile.fileSize) }} • {{ uploadedFile.mimeType }}</small>
            </div>
          </div>
          <button class="btn btn-blue toolbar-add-question" :disabled="!questions.length" @click="addAtCurrent">
            <i class="bi bi-plus-lg"></i> Thêm câu hỏi tại {{ formatTime(currentTime) }}
          </button>
        </div>
      </div>
      <aside class="app-card interaction-panel">
        <div class="interaction-panel-header p-3">
          <h2 class="h5 fw-bold mb-1">Câu hỏi tương tác</h2>
          <small class="text-secondary">{{ items.length }} mốc trong video</small>
        </div>
        <div class="interaction-scroll">
          <div
            v-for="item in items"
            :key="item.localKey"
            class="interaction"
            :class="{ selected: selected?.localKey === item.localKey }"
            @click="selectAndSeek(item)"
          >
            <span>{{ formatTime(item.time) }}</span>
            <div class="interaction-content">
              <strong>{{ item.label }}</strong
              ><small>{{ item.type }} • {{ item.score || 0 }} điểm</small>
            </div>
            <div class="interaction-actions">
              <button
                type="button"
                class="interaction-action edit"
                :aria-label="`Sửa câu hỏi tại ${formatTime(item.time)}`"
                title="Sửa thiết lập"
                @click.stop="openInteractionEditor(item)"
              >
                <i class="bi bi-pencil-square"></i>
              </button>
              <button
                type="button"
                class="interaction-action delete"
                :aria-label="`Xóa câu hỏi tại ${formatTime(item.time)}`"
                title="Xóa tương tác"
                @click.stop="requestDelete(item)"
              >
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </div>
          <div v-if="!items.length" class="empty-interactions">Chưa có tương tác cho video này.</div>
        </div>
      </aside>
    </div>

    <div class="app-card p-4 mt-4">
      <div class="d-flex flex-wrap justify-content-between gap-2 mb-2">
        <div>
          <h2 class="h5 fw-bold mb-1">Dòng thời gian tương tác</h2>
          <small class="text-secondary">Bấm vào timeline để kéo video đến thời điểm muốn thêm câu hỏi.</small>
        </div>
        <div class="timeline-info">
          <small>00:00 — {{ formatTime(form.durationSeconds) }}</small>
          <div class="timeline-legend">
            <span><i class="has-question"></i>Đã có câu hỏi</span
            ><span><i class="no-question"></i>Chưa có câu hỏi</span>
          </div>
        </div>
      </div>
      <div
        class="editor-timeline"
        role="slider"
        tabindex="0"
        aria-label="Chọn thời điểm trong video"
        aria-valuemin="0"
        :aria-valuemax="form.durationSeconds"
        :aria-valuenow="Math.round(currentTime)"
        @click="seekFromTimeline"
        @keydown.left.prevent="stepTimeline(-1)"
        @keydown.right.prevent="stepTimeline(1)"
      >
        <span
          v-for="(zone, index) in questionZones"
          :key="index"
          class="question-zone"
          :style="{ left: zone.left + '%', width: zone.width + '%' }"
        ></span
        ><span class="timeline-playhead" :style="{ left: progressPercent + '%' }"></span
        ><button
          v-for="item in items"
          :key="item.localKey"
          class="timeline-point"
          :style="{ left: markerPercent(item.time) + '%' }"
          @click.stop="selectAndSeek(item)"
        >
          <i class="bi bi-patch-question-fill"></i><span>{{ formatTime(item.time) }}</span>
        </button>
      </div>
      <div class="timeline-selected-time">
        <i class="bi bi-cursor-fill"></i> Đang chọn <strong>{{ formatTime(currentTime) }}</strong>
      </div>
    </div>

    <div v-if="interactionEditorOpen && selected" class="preview-backdrop" @click.self="closeInteractionEditor">
      <div
        class="interaction-editor-dialog app-card"
        role="dialog"
        aria-modal="true"
        aria-labelledby="interaction-editor-title"
      >
        <div class="preview-header">
          <div>
            <small>CHỈNH SỬA CÂU HỎI TẠI {{ formatTime(selected.time) }}</small>
            <h2 id="interaction-editor-title">
              <i class="bi bi-sliders2-vertical me-2 text-brand"></i>Thiết lập tương tác
            </h2>
          </div>
          <button type="button" class="btn btn-light btn-sm" aria-label="Đóng" @click="closeInteractionEditor">
            <i class="bi bi-x-lg"></i>
          </button>
        </div>
        <div class="row g-3">
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-clock me-1 text-brand"></i>Thời điểm (giây)</label
            ><input
              v-model.number="selected.time"
              type="number"
              min="0"
              :max="form.durationSeconds"
              class="form-control"
              @input="seekTo($event.target.value, true)"
            />
          </div>
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-ui-checks-grid me-1 text-brand"></i>Loại câu hỏi</label
            ><select v-model="questionTypeFilter" class="form-select">
              <option value="">Tất cả loại</option>
              <option>SINGLE_CHOICE</option>
              <option>MULTIPLE_CHOICE</option>
              <option>TRUE_FALSE</option>
              <option>SHORT_ANSWER</option>
            </select>
          </div>
          <div class="col-md-6 question-picker-wrap">
            <label class="form-label"><i class="bi bi-collection me-1 text-brand"></i>Câu hỏi từ ngân hàng</label>
            <div class="input-group">
              <button
                type="button"
                class="form-select text-start question-picker-button"
                @click="questionPickerOpen = !questionPickerOpen"
              >
                <span>{{ selected.label || 'Chọn câu hỏi' }}</span></button
              ><button type="button" class="btn btn-blue" title="Tạo nhanh câu hỏi mới" @click="openQuickQuestion">
                <i class="bi bi-plus-lg"></i><span class="d-none d-lg-inline ms-1">Tạo mới</span>
              </button>
            </div>
            <div v-if="questionPickerOpen" class="question-picker app-card">
              <div class="question-search">
                <i class="bi bi-search"></i
                ><input
                  v-model.trim="questionSearch"
                  class="form-control"
                  placeholder="Tìm nhanh nội dung câu hỏi..."
                  autofocus
                />
              </div>
              <small class="picker-summary"
                >{{ questions.length }} kết quả{{ questionTypeFilter ? ` • ${questionTypeFilter}` : '' }}</small
              ><button
                v-for="q in questions"
                :key="q.id"
                type="button"
                :class="{ active: selected.questionId === q.id }"
                @click="chooseQuestion(q)"
              >
                <span>{{ q.text }}</span
                ><small>{{ q.type }}</small>
              </button>
              <div v-if="!questionsLoading && !questions.length" class="picker-empty">
                Không tìm thấy câu hỏi phù hợp.
              </div>
              <div v-if="questionsLoading" class="picker-empty">
                <span class="spinner-border spinner-border-sm me-1"></span>Đang tìm...
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-star me-1 text-brand"></i>Điểm</label
            ><input v-model.number="selected.score" type="number" min="0" max="10000" class="form-control" />
          </div>
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-arrow-repeat me-1 text-brand"></i>Số lần làm</label
            ><input v-model.number="selected.attemptLimit" type="number" min="1" max="100" class="form-control" />
          </div>
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-toggle-on me-1 text-brand"></i>Trạng thái</label
            ><select v-model="selected.status" class="form-select">
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>
          <div class="col-md-3 form-check option-check">
            <input id="modal-required" v-model="selected.required" class="form-check-input" type="checkbox" /><label
              for="modal-required"
              ><i class="bi bi-shield-check me-1 text-brand"></i>Bắt buộc trả lời</label
            >
          </div>
          <div class="col-md-3 form-check option-check">
            <input id="modal-pause" v-model="selected.pauseVideo" class="form-check-input" type="checkbox" /><label
              for="modal-pause"
              ><i class="bi bi-pause-circle me-1 text-brand"></i>Tạm dừng video</label
            >
          </div>
          <div class="col-md-3 form-check option-check">
            <input id="modal-allow-skip" v-model="selected.allowSkip" class="form-check-input" type="checkbox" /><label
              for="modal-allow-skip"
              ><i class="bi bi-skip-forward-circle me-1 text-brand"></i>Cho phép bỏ qua</label
            >
          </div>
        </div>
        <div class="interaction-editor-actions">
          <button
            type="button"
            class="btn btn-light text-danger"
            :disabled="interactionSaving"
            @click="requestDelete(selected)"
          >
            <i class="bi bi-trash me-1"></i>Xóa
          </button>
          <div class="d-flex gap-2">
            <button type="button" class="btn btn-light" @click="closeInteractionEditor">Đóng</button
            ><button
              type="button"
              class="btn btn-brand"
              :disabled="interactionSaving || !selected.questionId"
              @click="saveInteractionAndClose"
            >
              <span v-if="interactionSaving" class="spinner-border spinner-border-sm me-1"></span
              ><i v-else class="bi bi-check-lg me-1"></i>Lưu tương tác
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="confirmDelete" class="preview-backdrop" @click.self="confirmDelete = false">
      <div class="confirm-dialog app-card">
        <span class="confirm-icon"><i class="bi bi-trash"></i></span>
        <h2>Xóa tương tác?</h2>
        <p>
          <strong>{{ selected?.label }}</strong
          ><br />Mốc câu hỏi sẽ không còn xuất hiện trên timeline và Student Player.
        </p>
        <div class="d-flex justify-content-end gap-2">
          <button class="btn btn-light" @click="confirmDelete = false">Hủy</button
          ><button class="btn btn-danger" :disabled="interactionSaving" @click="deleteInteraction">
            Xóa tương tác
          </button>
        </div>
      </div>
    </div>

    <div v-if="quickQuestionOpen" class="preview-backdrop" @click.self="quickQuestionOpen = false">
      <form class="quick-question-dialog app-card" @submit.prevent="saveQuickQuestion">
        <div class="preview-header">
          <div>
            <small>TẠO NHANH TRONG NGÂN HÀNG</small>
            <h2>Câu hỏi mới cho video</h2>
          </div>
          <button type="button" class="btn btn-light btn-sm" @click="quickQuestionOpen = false">
            <i class="bi bi-x-lg"></i>
          </button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label"><i class="bi bi-card-text me-1 text-brand"></i>Nội dung câu hỏi</label
            ><textarea v-model.trim="quickQuestion.questionText" class="form-control" rows="3" required></textarea>
          </div>
          <div class="col-md-5">
            <label class="form-label"><i class="bi bi-ui-checks-grid me-1 text-brand"></i>Loại câu hỏi</label
            ><select v-model="quickQuestion.questionType" class="form-select" @change="normalizeQuickQuestion">
              <option>SINGLE_CHOICE</option>
              <option>MULTIPLE_CHOICE</option>
              <option>TRUE_FALSE</option>
              <option>SHORT_ANSWER</option>
            </select>
          </div>
          <div class="col-md-4">
            <label class="form-label"><i class="bi bi-speedometer2 me-1 text-brand"></i>Độ khó</label
            ><select v-model="quickQuestion.difficulty" class="form-select">
              <option value="EASY">Dễ</option>
              <option value="MEDIUM">Trung bình</option>
              <option value="HARD">Khó</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label"><i class="bi bi-star me-1 text-brand"></i>Điểm mặc định</label
            ><input
              v-model.number="quickQuestion.defaultScore"
              type="number"
              min="0"
              max="10000"
              class="form-control"
            />
          </div>
        </div>
        <div v-if="quickQuestion.questionType !== 'SHORT_ANSWER'" class="quick-options mt-3">
          <div class="d-flex justify-content-between align-items-center">
            <strong><i class="bi bi-list-check me-1 text-brand"></i>Phương án trả lời</strong
            ><button type="button" class="btn btn-light btn-sm" @click="addQuickOption">
              <i class="bi bi-plus-lg"></i> Thêm phương án
            </button>
          </div>
          <div v-for="(option, index) in quickQuestion.options" :key="option.localKey" class="quick-option">
            <input
              v-if="quickQuestion.questionType === 'MULTIPLE_CHOICE'"
              v-model="option.isCorrect"
              type="checkbox"
              class="form-check-input"
            /><input
              v-else
              type="radio"
              name="quick-correct"
              class="form-check-input"
              :checked="option.isCorrect"
              @change="selectQuickCorrect(index)"
            /><input v-model.trim="option.optionCode" class="form-control option-code" required /><input
              v-model.trim="option.optionText"
              class="form-control"
              placeholder="Nội dung phương án"
              required
            /><button
              type="button"
              class="btn btn-light btn-sm"
              :disabled="quickQuestion.options.length <= 2"
              @click="quickQuestion.options.splice(index, 1)"
            >
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </div>
        <div v-else class="row g-3 mt-1">
          <div class="col-md-5">
            <label class="form-label"><i class="bi bi-check2-square me-1 text-brand"></i>Cách chấm</label
            ><select v-model="quickQuestion.shortAnswerMode" class="form-select">
              <option value="EXACT_MATCH">Khớp chính xác</option>
              <option value="CONTAINS">Có chứa đáp án</option>
              <option value="MANUAL_REVIEW">Giảng viên chấm</option>
            </select>
          </div>
          <div v-if="quickQuestion.shortAnswerMode !== 'MANUAL_REVIEW'" class="col-md-7">
            <label class="form-label"><i class="bi bi-key me-1 text-brand"></i>Đáp án mẫu</label
            ><input v-model.trim="quickQuestion.shortAnswer" class="form-control" required />
          </div>
        </div>
        <div class="d-flex justify-content-end gap-2 mt-4">
          <button type="button" class="btn btn-light" @click="quickQuestionOpen = false">Hủy</button
          ><button class="btn btn-brand" :disabled="quickQuestionSaving">
            <span v-if="quickQuestionSaving" class="spinner-border spinner-border-sm me-1"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu vào ngân hàng
          </button>
        </div>
      </form>
    </div>

    <div v-if="previewOpen" class="preview-backdrop" @click.self="closePreview">
      <div class="preview-dialog app-card">
        <div class="preview-header">
          <div>
            <small>CHẾ ĐỘ XEM HỌC VIÊN • DỮ LIỆU MỚI NHẤT</small>
            <h2>{{ form.title }}</h2>
          </div>
          <button class="btn btn-light btn-sm" @click="closePreview"><i class="bi bi-x-lg"></i></button>
        </div>
        <div v-if="playbackUrl" class="preview-player">
          <InteractiveVideoPlayer
            ref="previewPlayerRef"
            :key="previewKey"
            :source="playbackUrl"
            :poster="form.posterUrl"
            :duration-seconds="form.durationSeconds"
            :interactions="items"
            preview-mode
            allow-seek
            allow-speed
            :reset-key="previewKey"
            :on-submit-answer="submitPreviewAnswer"
          />
        </div>
        <div v-else class="preview-empty">Video chưa có file phát.</div>
        <div class="preview-list">
          <div v-for="item in items" :key="item.localKey" class="preview-question">
            <span>{{ formatTime(item.time) }}</span>
            <div>
              <strong>{{ item.label }}</strong
              ><small>{{ item.required ? 'Bắt buộc' : 'Tự chọn' }} • {{ item.score }} điểm</small>
            </div>
          </div>
          <div v-if="!items.length" class="text-secondary">Video chưa có câu hỏi tương tác.</div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { formatInteractionTime } from '../../utils/learningRules'
import InteractiveVideoPlayer from '../../components/video/InteractiveVideoPlayer.vue'

const route = useRoute(),
  videoRef = ref(null),
  items = ref([]),
  questions = ref([]),
  currentTime = ref(0),
  selected = ref(null)
const uploading = ref(false),
  saving = ref(false),
  interactionSaving = ref(false),
  previewLoading = ref(false),
  previewOpen = ref(false),
  previewPlayerRef = ref(null),
  previewKey = ref(0),
  uploadProgress = ref(0),
  message = ref(''),
  messageType = ref('success'),
  uploadedFile = ref(null)
const questionTypeFilter = ref(''),
  questionSearch = ref(''),
  questionPickerOpen = ref(false),
  questionsLoading = ref(false),
  quickQuestionOpen = ref(false),
  quickQuestionSaving = ref(false),
  confirmDelete = ref(false),
  interactionEditorOpen = ref(false)
const form = reactive({
  id: Number(route.params.id),
  lessonId: 0,
  title: 'Video bài giảng',
  videoUrl: '',
  posterUrl: '',
  durationSeconds: 600,
  allowSeek: false,
  allowSpeed: true,
  requiredWatchPercent: 80,
  status: 'ACTIVE'
})
const quickQuestion = reactive(blankQuickQuestion())
const formatTime = formatInteractionTime
const playbackUrl = computed(() => resolveApiAssetUrl(form.videoUrl))
const progressPercent = computed(() =>
  form.durationSeconds ? Math.min(100, (currentTime.value / form.durationSeconds) * 100) : 0
)
const questionZones = computed(() => {
  const duration = Math.max(1, form.durationSeconds),
    radius = Math.min(5, Math.max(2, duration / 48))
  const ranges = items.value
    .map((item) => ({ start: Math.max(0, item.time - radius), end: Math.min(duration, item.time + radius) }))
    .sort((a, b) => a.start - b.start)
  const merged = []
  for (const range of ranges) {
    const last = merged[merged.length - 1]
    if (last && range.start <= last.end) last.end = Math.max(last.end, range.end)
    else merged.push({ ...range })
  }
  return merged.map((range) => ({
    left: (range.start / duration) * 100,
    width: Math.max(0.8, ((range.end - range.start) / duration) * 100)
  }))
})
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)

onMounted(async () => {
  await Promise.all([loadVideo(), loadQuestions()])
  await loadInteractions()
})
let questionSearchTimer
watch([questionSearch, questionTypeFilter], () => {
  clearTimeout(questionSearchTimer)
  questionSearchTimer = setTimeout(loadQuestions, 250)
})
async function loadVideo() {
  try {
    const data = await axiosClient.get(`/videos/${form.id}`, { params: { _fresh: Date.now() } })
    form.lessonId = Number(pick(data, 'LessonId', 'lessonId') || 0)
    form.title = pick(data, 'Title', 'title') || form.title
    form.videoUrl = pick(data, 'VideoUrl', 'videoUrl') || ''
    form.posterUrl = pick(data, 'PosterUrl', 'posterUrl') || ''
    form.durationSeconds = Number(pick(data, 'DurationSeconds', 'durationSeconds') || 600)
    form.allowSeek = Boolean(pick(data, 'AllowSeek', 'allowSeek'))
    form.allowSpeed = Boolean(pick(data, 'AllowSpeed', 'allowSpeed') ?? true)
    form.requiredWatchPercent = Number(pick(data, 'RequiredWatchPercent', 'requiredWatchPercent') || 80)
    form.status = pick(data, 'Status', 'status') || 'ACTIVE'
  } catch (error) {
    showMessage(error.message, 'danger')
  }
}
async function loadQuestions() {
  questionsLoading.value = true
  try {
    const data = await axiosClient.get('/questions', {
      params: {
        search: questionSearch.value || undefined,
        type: questionTypeFilter.value || undefined,
        pageSize: 50,
        _fresh: Date.now()
      }
    })
    const rows = pick(data, 'items', 'Items') || []
    questions.value = rows.map((q) => ({
      id: Number(pick(q, 'Id', 'id')),
      text: pick(q, 'QuestionText', 'questionText') || '',
      type: pick(q, 'QuestionType', 'questionType') || 'SINGLE_CHOICE'
    }))
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    questionsLoading.value = false
  }
}
async function loadInteractions() {
  const data = await axiosClient.get(`/videos/${form.id}/interactions`, { params: { _fresh: Date.now() } })
  items.value = (Array.isArray(data) ? data : []).map((row, index) => ({
    id: Number(pick(row, 'Id', 'id')),
    localKey: `db-${pick(row, 'Id', 'id')}`,
    questionId: Number(pick(row, 'QuestionId', 'questionId')),
    time: Number(pick(row, 'TimeSeconds', 'timeSeconds') || 0),
    endTimeSeconds: pick(row, 'EndTimeSeconds', 'endTimeSeconds') ?? null,
    label: pick(row, 'QuestionText', 'questionText') || 'Câu hỏi',
    description: pick(row, 'Description', 'description') || '',
    type: pick(row, 'QuestionType', 'questionType') || 'SINGLE_CHOICE',
    interactionType: pick(row, 'InteractionType', 'interactionType') || 'QUESTION',
    required: Boolean(pick(row, 'Required', 'required')),
    pauseVideo: Boolean(pick(row, 'PauseVideo', 'pauseVideo')),
    allowSkip: Boolean(pick(row, 'AllowSkip', 'allowSkip')),
    score: Number(pick(row, 'Score', 'score') || 0),
    attemptLimit: Number(pick(row, 'AttemptLimit', 'attemptLimit') || 1),
    sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
    status: pick(row, 'Status', 'status') || 'ACTIVE',
    options: pick(row, 'Options', 'options')
  }))
  items.value.sort((a, b) => a.time - b.time)
  selected.value = selected.value
    ? items.value.find((x) => x.id === selected.value.id) || items.value[0] || null
    : items.value[0] || null
}
async function uploadVideo(event) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file) return
  uploading.value = true
  uploadProgress.value = 0
  message.value = ''
  try {
    const body = new FormData()
    body.append('file', file)
    const result = await axiosClient.post('/videos/upload', body, {
      timeout: 0,
      onUploadProgress: (e) => (uploadProgress.value = e.total ? Math.round((e.loaded / e.total) * 100) : 0)
    })
    form.videoUrl = pick(result, 'videoUrl', 'VideoUrl')
    uploadedFile.value = {
      originalFileName: pick(result, 'originalFileName', 'OriginalFileName'),
      fileSize: Number(pick(result, 'fileSize', 'FileSize')),
      mimeType: pick(result, 'mimeType', 'MimeType')
    }
    showMessage(
      'Upload thành công. File đã được lưu trong wwwroot/Media/Video. Hãy bấm “Lưu video” để ghi URL tương đối vào SQL.'
    )
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    uploading.value = false
  }
}
async function saveVideo() {
  saving.value = true
  message.value = ''
  try {
    await axiosClient.put(`/videos/${form.id}`, {
      lessonId: form.lessonId,
      title: form.title,
      videoUrl: form.videoUrl || null,
      posterUrl: form.posterUrl || null,
      durationSeconds: Math.max(1, Math.round(form.durationSeconds)),
      allowSeek: form.allowSeek,
      allowSpeed: form.allowSpeed,
      requiredWatchPercent: form.requiredWatchPercent,
      status: form.status
    })
    showMessage('Đã lưu video. SQL chỉ lưu URL tương đối ' + form.videoUrl)
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function saveInteraction() {
  if (!selected.value?.questionId) return false
  interactionSaving.value = true
  message.value = ''
  try {
    const body = {
      questionId: selected.value.questionId,
      timeSeconds: Math.max(0, Math.round(selected.value.time)),
      endTimeSeconds: selected.value.endTimeSeconds,
      interactionType: selected.value.interactionType || 'QUESTION',
      required: selected.value.required,
      pauseVideo: selected.value.pauseVideo,
      allowSkip: selected.value.allowSkip,
      score: Number(selected.value.score) || 0,
      attemptLimit: Math.max(1, Number(selected.value.attemptLimit) || 1),
      sortOrder: selected.value.sortOrder || items.value.indexOf(selected.value) + 1,
      status: selected.value.status || 'ACTIVE'
    }
    if (selected.value.id) await axiosClient.put(`/video-interactions/${selected.value.id}`, body)
    else await axiosClient.post(`/videos/${form.id}/interactions`, body)
    await loadInteractions()
    showMessage('Đã lưu tương tác.')
    return true
  } catch (error) {
    showMessage(error.message, 'danger')
    return false
  } finally {
    interactionSaving.value = false
  }
}
async function saveInteractionAndClose() {
  if (await saveInteraction()) interactionEditorOpen.value = false
}
async function deleteInteraction() {
  if (!selected.value) return
  const deleting = { id: selected.value.id, localKey: selected.value.localKey }
  if (!deleting.id) {
    items.value = items.value.filter((item) => item.localKey !== deleting.localKey)
    confirmDelete.value = false
    interactionEditorOpen.value = false
    selected.value = items.value[0] || null
    showMessage('Đã bỏ câu hỏi chưa lưu khỏi danh sách.')
    return
  }
  interactionSaving.value = true
  try {
    await axiosClient.delete(`/video-interactions/${deleting.id}`)
    confirmDelete.value = false
    interactionEditorOpen.value = false
    selected.value = null
    await loadInteractions()
    showMessage('Đã xóa tương tác khỏi timeline và Student Player.')
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    interactionSaving.value = false
  }
}
async function openPreview() {
  previewLoading.value = true
  message.value = ''
  try {
    await Promise.all([loadVideo(), loadQuestions(), loadInteractions()])
    previewKey.value++
    previewOpen.value = true
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    previewLoading.value = false
  }
}
function closePreview() {
  previewPlayerRef.value?.pause()
  previewOpen.value = false
}
async function submitPreviewAnswer(item, answers) {
  return axiosClient.post(`/videos/${form.id}/preview-answer`, {
    interactionId: item.id,
    questionId: item.questionId,
    answers
  })
}
function chooseQuestion(q) {
  selected.value.questionId = q.id
  selected.value.label = q.text
  selected.value.type = q.type
  questionPickerOpen.value = false
}
function openQuickQuestion() {
  Object.assign(quickQuestion, blankQuickQuestion(questionTypeFilter.value || 'SINGLE_CHOICE'))
  quickQuestionOpen.value = true
  questionPickerOpen.value = false
}
async function saveQuickQuestion() {
  quickQuestionSaving.value = true
  message.value = ''
  try {
    const isShort = quickQuestion.questionType === 'SHORT_ANSWER'
    const result = await axiosClient.post('/questions', {
      questionType: quickQuestion.questionType,
      questionText: quickQuestion.questionText,
      description: null,
      explanation: quickQuestion.explanation || null,
      difficulty: quickQuestion.difficulty,
      defaultScore: Number(quickQuestion.defaultScore) || 0,
      shortAnswerMode: isShort ? quickQuestion.shortAnswerMode : null,
      status: 'ACTIVE',
      options: isShort
        ? []
        : quickQuestion.options.map((o, index) => ({
            optionCode: o.optionCode,
            optionText: o.optionText,
            isCorrect: o.isCorrect,
            sortOrder: index + 1
          })),
      answerKeys:
        isShort && quickQuestion.shortAnswerMode !== 'MANUAL_REVIEW'
          ? [{ answerText: quickQuestion.shortAnswer, isCaseSensitive: false, sortOrder: 1 }]
          : []
    })
    const id = Number(pick(result, 'id', 'Id'))
    questionSearch.value = ''
    questionTypeFilter.value = quickQuestion.questionType
    await loadQuestions()
    const created = questions.value.find((q) => q.id === id) || {
      id,
      text: quickQuestion.questionText,
      type: quickQuestion.questionType
    }
    chooseQuestion(created)
    quickQuestionOpen.value = false
    showMessage('Đã tạo câu hỏi mới trong ngân hàng và chọn cho tương tác hiện tại.')
  } catch (error) {
    showMessage(error.message, 'danger')
  } finally {
    quickQuestionSaving.value = false
  }
}
function blankQuickQuestion(type = 'SINGLE_CHOICE') {
  return {
    questionType: type,
    questionText: '',
    difficulty: 'EASY',
    defaultScore: 10,
    explanation: '',
    shortAnswerMode: 'EXACT_MATCH',
    shortAnswer: '',
    options: [quickOption('A', '', true), quickOption('B', '', false)]
  }
}
function quickOption(code, text, isCorrect) {
  return { localKey: `${Date.now()}-${Math.random()}`, optionCode: code, optionText: text, isCorrect }
}
function normalizeQuickQuestion() {
  if (quickQuestion.questionType === 'TRUE_FALSE')
    quickQuestion.options = [quickOption('A', 'Đúng', true), quickOption('B', 'Sai', false)]
  else if (quickQuestion.questionType !== 'SHORT_ANSWER' && quickQuestion.options.length < 2)
    quickQuestion.options = [quickOption('A', '', true), quickOption('B', '', false)]
  if (quickQuestion.questionType === 'SINGLE_CHOICE')
    selectQuickCorrect(
      quickQuestion.options.findIndex((x) => x.isCorrect) >= 0 ? quickQuestion.options.findIndex((x) => x.isCorrect) : 0
    )
}
function addQuickOption() {
  quickQuestion.options.push(quickOption(String.fromCharCode(65 + quickQuestion.options.length), '', false))
}
function selectQuickCorrect(index) {
  if (quickQuestion.questionType !== 'MULTIPLE_CHOICE')
    quickQuestion.options.forEach((option, i) => (option.isCorrect = i === index))
}
function syncTime() {
  if (videoRef.value) currentTime.value = videoRef.value.currentTime
}
function syncMetadata() {
  if (videoRef.value?.duration && Number.isFinite(videoRef.value.duration))
    form.durationSeconds = Math.round(videoRef.value.duration)
}
function seekTo(time, pause = false) {
  const target = Math.min(form.durationSeconds, Math.max(0, Number(time) || 0))
  currentTime.value = target
  if (videoRef.value) {
    if (pause) videoRef.value.pause()
    videoRef.value.currentTime = target
  }
}
function selectAndSeek(item) {
  selected.value = item
  seekTo(item.time, true)
}
function openInteractionEditor(item) {
  selectAndSeek(item)
  questionPickerOpen.value = false
  interactionEditorOpen.value = true
}
function closeInteractionEditor() {
  questionPickerOpen.value = false
  interactionEditorOpen.value = false
}
function requestDelete(item) {
  selectAndSeek(item)
  questionPickerOpen.value = false
  confirmDelete.value = true
}
function seekFromTimeline(event) {
  const rect = event.currentTarget.getBoundingClientRect()
  if (!rect.width) return
  const ratio = Math.min(1, Math.max(0, (event.clientX - rect.left) / rect.width))
  seekTo(ratio * form.durationSeconds, true)
}
function stepTimeline(direction) {
  seekTo(currentTime.value + direction, true)
}
function markerPercent(time) {
  return form.durationSeconds ? Math.min(100, (time / form.durationSeconds) * 100) : 0
}
function addAtCurrent() {
  const q = questions.value[0]
  if (!q) return
  videoRef.value?.pause()
  const item = {
    id: 0,
    localKey: `new-${Date.now()}`,
    questionId: q.id,
    time: Math.round(currentTime.value),
    endTimeSeconds: null,
    label: q.text,
    type: q.type,
    interactionType: 'QUESTION',
    score: 10,
    required: true,
    pauseVideo: true,
    allowSkip: false,
    attemptLimit: 1,
    sortOrder: items.value.length + 1,
    status: 'ACTIVE'
  }
  items.value.push(item)
  items.value.sort((a, b) => a.time - b.time)
  openInteractionEditor(item)
}
function showMessage(text, type = 'success') {
  message.value = text
  messageType.value = type
}
function formatBytes(bytes) {
  if (!bytes) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB']
  const index = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1)
  return `${(bytes / 1024 ** index).toFixed(index ? 1 : 0)} ${units[index]}`
}
</script>

<style scoped src="../../assets/css/pages/cms/video-editor.css"></style>
