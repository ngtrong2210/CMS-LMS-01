<template>
  <section>
    <div class="d-flex justify-content-end align-items-center gap-2 mb-3">
      <span class="badge badge-soft-primary"
        ><i class="bi bi-clock"></i> Thời gian học {{ formatStudyTime(studySeconds) }}</span
      >
      <span v-if="isVideoLesson" class="badge badge-soft-success">Đã xem {{ Math.round(progress.watchPercent) }}%</span>
    </div>
    <div v-if="loading" class="app-card p-5 text-center">
      <span class="spinner-border text-success"></span>
      <p class="text-secondary mt-3 mb-0">Đang tải bài học...</p>
    </div>
    <div v-else-if="error" class="app-card p-5 text-center">
      <i class="bi bi-exclamation-circle fs-1 text-danger"></i>
      <h1 class="h4 mt-3">Không thể mở bài học</h1>
      <p class="text-secondary">{{ error }}</p>
      <button class="btn btn-action-refresh" @click="loadPlayer"><i class="bi bi-arrow-clockwise"></i> Thử lại</button>
    </div>
    <template v-else>
      <div class="player-grid app-card overflow-hidden">
        <div class="video-area">
          <div class="video-stage">
            <InteractiveVideoPlayer
              v-if="isVideoLesson"
              ref="playerRef"
              :key="playerKey"
              :source="video.url"
              :source-type="video.sourceType"
              :poster="video.poster"
              :duration-seconds="video.duration"
              :interactions="interactions"
              :answered-interaction-ids="answeredInteractionIds"
              :allow-seek="video.allowSeek"
              :allow-speed="video.allowSpeed"
              :initial-time="progress.currentTime"
              :max-watched-time="progress.maxWatchedTime"
              :reset-key="playerKey"
              :on-submit-answer="submitInteractionAnswer"
              @progress="handleProgress"
              @answered="handleAnswered"
            />
            <article v-else-if="lesson.type === 'EDITOR'" class="learning-content editor-content">
              <div class="content-type-icon"><i class="bi bi-journal-richtext"></i></div>
              <div class="lesson-html" v-html="sanitizedContentHtml"></div>
            </article>
            <article v-else-if="lesson.type === 'DOCUMENT'" class="learning-content document-content">
              <div class="content-type-icon"><i class="bi bi-file-earmark-pdf"></i></div>
              <h2>Tài liệu bài học</h2>
              <p>Đọc tài liệu và duy trì trang học để hệ thống ghi nhận thời gian.</p>
              <a
                v-if="lesson.documentUrl"
                class="btn btn-action-view"
                :href="resolveApiAssetUrl(lesson.documentUrl)"
                target="_blank"
                rel="noopener"
                ><i class="bi bi-box-arrow-up-right"></i> Mở tài liệu</a
              >
              <span v-else class="text-secondary">Giảng viên chưa cập nhật file tài liệu.</span>
            </article>
            <article v-else-if="lesson.type === 'ASSIGNMENT'" class="learning-content assignment-content">
              <div class="assignment-heading">
                <span class="content-type-icon"><i class="bi bi-cloud-arrow-up"></i></span>
                <div>
                  <h2>Bài tập nộp file</h2>
                  <p v-if="lesson.dueAt">Hạn nộp: {{ dateTimeText(lesson.dueAt) }}</p>
                  <p v-else>Không giới hạn thời gian nộp.</p>
                </div>
              </div>
              <div v-if="lesson.contentHtml" class="lesson-html" v-html="sanitizedContentHtml"></div>
              <p v-else>{{ lesson.description || 'Thực hiện yêu cầu và nộp bài tại biểu mẫu bên dưới.' }}</p>
              <a
                v-if="lesson.documentUrl"
                class="assignment-resource"
                :href="resolveApiAssetUrl(lesson.documentUrl)"
                target="_blank"
                rel="noopener"
                ><i class="bi bi-paperclip"></i> Tải đề bài / tài liệu đính kèm</a
              >
              <div v-if="assignmentAvailability" class="assignment-availability">
                <i class="bi bi-info-circle"></i> {{ assignmentAvailability }}
              </div>
              <form v-else class="assignment-form" @submit.prevent="submitAssignment">
                <label
                  ><span>Nội dung ghi chú</span
                  ><textarea
                    v-model.trim="submissionText"
                    class="form-control"
                    rows="4"
                    placeholder="Mô tả bài làm hoặc đường dẫn bổ sung..."
                  ></textarea>
                </label>
                <label
                  ><span>File bài làm</span
                  ><input
                    class="form-control"
                    type="file"
                    accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.txt,.png,.jpg,.jpeg"
                    @change="selectSubmissionFile"
                  /><small>Tối đa {{ lesson.maxSubmissionFileSizeMB }} MB</small></label
                >
                <div class="assignment-actions">
                  <button
                    type="button"
                    class="btn btn-action-view"
                    :disabled="submitting || (!submissionText && !submissionFile)"
                    @click="saveAssignmentDraft"
                  >
                    <i class="bi bi-floppy"></i> Lưu nháp</button
                  ><button class="btn btn-action-save" :disabled="submitting || (!submissionText && !submissionFile)">
                    <span v-if="submitting" class="spinner-border spinner-border-sm"></span
                    ><i v-else class="bi bi-send"></i> Nộp bài
                  </button>
                </div>
              </form>
              <div v-if="submissions.length" class="submission-history">
                <h3>Lịch sử nộp bài</h3>
                <div v-for="item in submissions" :key="item.id">
                  <span class="attempt">Lần {{ item.attemptNumber }}</span>
                  <div>
                    <strong>{{ submissionStatus(item.status) }}</strong
                    ><small
                      >{{ dateTimeText(item.submittedAt)
                      }}<template v-if="item.fileName"> · {{ item.fileName }}</template></small
                    ><small v-if="item.feedback" class="teacher-feedback">Nhận xét: {{ item.feedback }}</small>
                  </div>
                  <span v-if="item.score != null" class="submission-score"
                    >{{ item.score }}/{{ lesson.assignmentMaxScore }} điểm</span
                  >
                </div>
              </div>
            </article>
            <article v-else class="learning-content document-content">
              <div class="content-type-icon"><i class="bi bi-ui-checks"></i></div>
              <h2>Bài kiểm tra</h2>
              <p>Nội dung kiểm tra sẽ được mở tại đây.</p>
            </article>
          </div>
          <div class="lesson-meta">
            <div>
              <span class="badge badge-soft-primary">{{ lesson.type }}</span>
              <h1>{{ lesson.title }}</h1>
              <p>{{ lesson.description || 'Học qua video và hoàn thành các câu hỏi tương tác.' }}</p>
            </div>
            <div class="score">
              <strong>{{ currentScore }}</strong
              ><small>Điểm hiện tại</small>
            </div>
          </div>
        </div>
        <aside class="content-panel">
          <div class="p-3">
            <strong>Nội dung môn học</strong
            ><small class="d-block text-secondary">{{ completedLessons }}/{{ lessonCount }} bài đã hoàn thành</small>
          </div>
          <div class="chapter-list">
            <div v-for="chapter in chapters" :key="chapter.id" class="chapter">
              <strong>{{ chapter.title }}</strong
              ><RouterLink
                v-for="item in chapter.lessons"
                :key="item.id"
                :to="`/lms/courses/${course.id}/lessons/${item.id}`"
                :class="{ active: item.id === lesson.id }"
                ><i
                  :class="[
                    'bi',
                    item.completed ? 'bi-check-circle-fill' : item.id === lesson.id ? 'bi-play-circle' : 'bi-circle'
                  ]"
                ></i
                ><span>{{ item.title }}</span
                ><small>{{ formatTime(item.duration) }}</small></RouterLink
              >
            </div>
          </div>
        </aside>
      </div>
      <div v-if="isVideoLesson" class="app-card p-4 mt-4">
        <h2 class="h5 fw-bold">Mốc câu hỏi tương tác</h2>
        <div v-if="interactions.length" class="interaction-list">
          <button
            v-for="item in interactions"
            :key="item.id"
            type="button"
            :class="{ answered: item.answered }"
            @click="playerRef?.openQuestion(item)"
          >
            <span>{{ formatTime(item.timeSeconds) }}</span
            ><i :class="['bi', item.answered ? 'bi-check-circle-fill' : 'bi-patch-question']"></i>
            <div>
              <strong>{{ item.label }}</strong
              ><small>{{ questionTypeLabel(item.type) }} • {{ item.score }} điểm</small>
            </div>
          </button>
        </div>
        <p v-else class="text-secondary mb-0">Bài học này không có câu hỏi tương tác.</p>
      </div>
      <div v-if="!isVideoLesson && lesson.type !== 'ASSIGNMENT'" class="lesson-completion app-card mt-4">
        <div>
          <strong>Hoàn thành nội dung này?</strong
          ><small>Hệ thống chỉ ghi nhận thời gian hợp lệ từ heartbeat khi trang đang hoạt động.</small>
        </div>
        <button class="btn btn-action-save" :disabled="completing" @click="markLessonComplete">
          <span v-if="completing" class="spinner-border spinner-border-sm"></span
          ><i v-else class="bi bi-check2-circle"></i> Đánh dấu hoàn thành
        </button>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { questionTypeLabel } from '../../utils/displayLabels'
import { formatInteractionTime } from '../../utils/learningRules'
import InteractiveVideoPlayer from '../../components/video/InteractiveVideoPlayer.vue'
import { normalizeVideoSource } from '../../utils/videoSources'
import { sanitizeLearningHtml } from '../../utils/sanitizeHtml'

const route = useRoute(),
  playerRef = ref(null),
  loading = ref(true),
  error = ref(''),
  interactions = ref([]),
  chapters = ref([]),
  answeredInteractionIds = ref([]),
  playerKey = ref(0),
  studySessionId = ref(''),
  studySeconds = ref(0),
  submissions = ref([]),
  submissionText = ref(''),
  submissionFile = ref(null),
  submitting = ref(false),
  completing = ref(false)
const lesson = reactive({
    id: 0,
    title: '',
    description: '',
    type: 'VIDEO',
    duration: 0,
    passingScore: 0,
    contentHtml: '',
    documentUrl: '',
    assignmentStartAt: null,
    dueAt: null,
    assignmentMaxScore: 100,
    maxSubmissionAttempts: 3,
    maxSubmissionFileSizeMB: 50,
    allowLateSubmission: false
  }),
  course = reactive({ id: 0, title: '' }),
  video = reactive({
    id: 0,
    sourceType: 'LOCAL',
    url: '',
    poster: '',
    duration: 0,
    allowSeek: false,
    allowSpeed: true,
    requiredWatchPercent: 80
  }),
  progress = reactive({ currentTime: 0, maxWatchedTime: 0, watchPercent: 0 })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const formatTime = formatInteractionTime
const currentScore = ref(0),
  lastSavedAt = ref(0),
  savingProgress = ref(false)
const lessonCount = computed(() => chapters.value.reduce((total, chapter) => total + chapter.lessons.length, 0)),
  isVideoLesson = computed(() => ['VIDEO', 'INTERACTIVE_VIDEO'].includes(lesson.type)),
  sanitizedContentHtml = computed(() =>
    sanitizeLearningHtml(lesson.contentHtml || '<p>Bài học chưa có nội dung soạn thảo.</p>')
  ),
  assignmentAvailability = computed(() => {
    const now = Date.now()
    if (lesson.assignmentStartAt && now < new Date(lesson.assignmentStartAt).getTime())
      return `Bài tập mở lúc ${dateTimeText(lesson.assignmentStartAt)}.`
    if (lesson.dueAt && now > new Date(lesson.dueAt).getTime() && !lesson.allowLateSubmission)
      return `Đã hết hạn nộp lúc ${dateTimeText(lesson.dueAt)}.`
    const submittedAttempts = submissions.value.filter((item) => item.status !== 'DRAFT').length
    if (submittedAttempts >= lesson.maxSubmissionAttempts)
      return `Bạn đã sử dụng đủ ${lesson.maxSubmissionAttempts} lần nộp.`
    return ''
  }),
  completedLessons = computed(() =>
    chapters.value.reduce((total, chapter) => total + chapter.lessons.filter((x) => x.completed).length, 0)
  )
const activityEvents = ['mousemove', 'keydown', 'click', 'scroll']
let lastActivityAt = Date.now()
const recordActivity = () => (lastActivityAt = Date.now())
onMounted(() => {
  activityEvents.forEach((eventName) => window.addEventListener(eventName, recordActivity, { passive: true }))
  loadPlayer()
})
onBeforeUnmount(() => {
  activityEvents.forEach((eventName) => window.removeEventListener(eventName, recordActivity))
  playerRef.value?.pause()
  void saveProgress()
  void stopStudySession(false)
})
watch(
  () => route.params.lessonId,
  () => {
    playerRef.value?.pause()
    void Promise.all([saveProgress(), stopStudySession(false)]).finally(loadPlayer)
  }
)
async function loadPlayer() {
  loading.value = true
  error.value = ''
  try {
    const data = await axiosClient.get(`/lms/lessons/${Number(route.params.lessonId)}/player`, {
      params: { _fresh: Date.now() }
    })
    const l = pick(data, 'lesson', 'Lesson') || {},
      c = pick(data, 'course', 'Course') || {},
      v = pick(data, 'video', 'Video') || {},
      p = pick(data, 'progress', 'Progress') || {}
    Object.assign(lesson, {
      id: Number(pick(l, 'Id', 'id')),
      title: pick(l, 'Title', 'title') || '',
      description: pick(l, 'Description', 'description') || '',
      type: pick(l, 'LessonType', 'lessonType') || 'VIDEO',
      duration: Number(pick(l, 'DurationSeconds', 'durationSeconds') || 0),
      passingScore: Number(pick(l, 'PassingScore', 'passingScore') || 0),
      contentHtml: pick(l, 'ContentHtml', 'contentHtml') || '',
      documentUrl: pick(l, 'DocumentUrl', 'documentUrl') || '',
      assignmentStartAt: pick(l, 'AssignmentStartAt', 'assignmentStartAt') || null,
      dueAt: pick(l, 'DueAt', 'dueAt') || null,
      assignmentMaxScore: Number(pick(l, 'AssignmentMaxScore', 'assignmentMaxScore') || 100),
      maxSubmissionAttempts: Number(pick(l, 'MaxSubmissionAttempts', 'maxSubmissionAttempts') || 3),
      maxSubmissionFileSizeMB: Number(pick(l, 'MaxSubmissionFileSizeMB', 'maxSubmissionFileSizeMB') || 50),
      allowLateSubmission: Boolean(pick(l, 'AllowLateSubmission', 'allowLateSubmission'))
    })
    Object.assign(course, { id: Number(pick(c, 'Id', 'id')), title: pick(c, 'Title', 'title') || '' })
    Object.assign(video, {
      id: Number(pick(v, 'Id', 'id') || 0),
      sourceType: normalizeVideoSource(pick(v, 'SourceType', 'sourceType')),
      url:
        normalizeVideoSource(pick(v, 'SourceType', 'sourceType')) === 'YOUTUBE'
          ? pick(v, 'VideoUrl', 'videoUrl') || ''
          : resolveApiAssetUrl(pick(v, 'VideoUrl', 'videoUrl') || ''),
      poster: resolveApiAssetUrl(pick(v, 'PosterUrl', 'posterUrl') || ''),
      duration: Number(pick(v, 'DurationSeconds', 'durationSeconds') || lesson.duration),
      allowSeek: Boolean(pick(v, 'AllowSeek', 'allowSeek')),
      allowSpeed: Boolean(pick(v, 'AllowSpeed', 'allowSpeed') ?? true),
      requiredWatchPercent: Number(pick(v, 'RequiredWatchPercent', 'requiredWatchPercent') || 80)
    })
    Object.assign(progress, {
      currentTime: Number(pick(p, 'CurrentTimeSeconds', 'currentTimeSeconds') || 0),
      maxWatchedTime: Number(pick(p, 'MaxWatchedTimeSeconds', 'maxWatchedTimeSeconds') || 0),
      watchPercent: Number(pick(p, 'WatchPercent', 'watchPercent') || 0)
    })
    const answeredRows = pick(data, 'answeredInteractions', 'AnsweredInteractions') || []
    const answeredMap = new Map(answeredRows.map((row) => [Number(pick(row, 'InteractionId', 'interactionId')), row]))
    answeredInteractionIds.value = [...answeredMap.keys()]
    const rows = pick(data, 'interactions', 'Interactions') || []
    interactions.value = rows.map((row) => {
      const answered = answeredMap.get(Number(pick(row, 'Id', 'id')))
      return {
        id: Number(pick(row, 'Id', 'id')),
        questionId: Number(pick(row, 'QuestionId', 'questionId')),
        videoId: Number(pick(row, 'VideoId', 'videoId')),
        timeSeconds: Number(pick(row, 'TimeSeconds', 'timeSeconds') || 0),
        label: pick(row, 'QuestionText', 'questionText') || 'Câu hỏi',
        description: pick(row, 'Description', 'description') || '',
        type: pick(row, 'QuestionType', 'questionType') || 'SINGLE_CHOICE',
        required: Boolean(pick(row, 'Required', 'required')),
        pauseVideo: Boolean(pick(row, 'PauseVideo', 'pauseVideo')),
        allowSkip: Boolean(pick(row, 'AllowSkip', 'allowSkip')),
        score: Number(pick(row, 'Score', 'score') || 0),
        attemptLimit: Number(pick(row, 'AttemptLimit', 'attemptLimit') || 1),
        answered: Boolean(answered),
        attempts: Number(pick(answered, 'AttemptNumber', 'attemptNumber') || 0),
        options: pick(row, 'Options', 'options')
      }
    })
    currentScore.value = answeredRows.reduce(
      (sum, row) => sum + Number(pick(row, 'ScoreAwarded', 'scoreAwarded') || 0),
      0
    )
    lastSavedAt.value = progress.currentTime
    playerKey.value++
    if (course.id) {
      const detail = await axiosClient.get(`/lms/courses/${course.id}`, { params: { _fresh: Date.now() } })
      mapCourseContent(detail)
    }
    submissionText.value = ''
    submissionFile.value = null
    if (lesson.type === 'ASSIGNMENT') await loadSubmissions()
    else submissions.value = []
    await startStudySession()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
let studyTimer
async function startStudySession() {
  clearInterval(studyTimer)
  studySeconds.value = 0
  const result = await axiosClient.post('/lms/study-sessions', {
    courseId: course.id,
    lessonId: lesson.id,
    pageUrl: window.location.pathname,
    clientSessionKey: window.crypto?.randomUUID?.() || String(Date.now())
  })
  studySessionId.value = pick(result, 'StudySessionID', 'studySessionID') || ''
  studyTimer = setInterval(async () => {
    const isActive = document.visibilityState === 'visible' && Date.now() - lastActivityAt < 90000
    if (isActive) studySeconds.value += 1
    if (isActive && studySeconds.value > 0 && studySeconds.value % 30 === 0 && studySessionId.value) {
      try {
        await axiosClient.put(`/lms/study-sessions/${studySessionId.value}/heartbeat`)
      } catch {
        // Phiên sẽ được kết thúc khi người học rời trang.
      }
    }
  }, 1000)
}
async function stopStudySession(isCompleted) {
  clearInterval(studyTimer)
  const id = studySessionId.value
  studySessionId.value = ''
  if (!id) return
  try {
    await axiosClient.post(`/lms/study-sessions/${id}/end`, { isCompleted })
  } catch {
    // Trình duyệt có thể đang đóng nên không làm gián đoạn trải nghiệm học.
  }
}
async function loadSubmissions() {
  const rows = await axiosClient.get(`/lms/lessons/${lesson.id}/submissions`)
  submissions.value = (rows || []).map((row) => ({
    id: Number(pick(row, 'AssignmentSubmissionID', 'assignmentSubmissionID')),
    attemptNumber: Number(pick(row, 'AttemptNumber', 'attemptNumber')),
    submittedAt: pick(row, 'SubmittedAt', 'submittedAt'),
    status: pick(row, 'SubmissionStatus', 'submissionStatus'),
    score: pick(row, 'Score', 'score'),
    fileName: pick(row, 'OriginalFileName', 'originalFileName'),
    submissionText: pick(row, 'SubmissionText', 'submissionText') || '',
    feedback: pick(row, 'Feedback', 'feedback') || ''
  }))
  const draft = submissions.value.find((item) => item.status === 'DRAFT')
  if (draft && !submissionText.value) submissionText.value = draft.submissionText
}
function selectSubmissionFile(event) {
  submissionFile.value = event.target.files?.[0] || null
}
async function submitAssignment() {
  submitting.value = true
  try {
    const body = new FormData()
    if (submissionText.value) body.append('submissionText', submissionText.value)
    if (submissionFile.value) body.append('file', submissionFile.value)
    await axiosClient.post(`/lms/lessons/${lesson.id}/submissions`, body)
    submissionText.value = ''
    submissionFile.value = null
    await loadSubmissions()
  } catch (e) {
    error.value = e.message
  } finally {
    submitting.value = false
  }
}
async function saveAssignmentDraft() {
  await saveAssignment('/submission-draft', false)
}
async function saveAssignment(path, clearAfterSave) {
  submitting.value = true
  try {
    const body = new FormData()
    if (submissionText.value) body.append('submissionText', submissionText.value)
    if (submissionFile.value) body.append('file', submissionFile.value)
    await axiosClient.put(`/lms/lessons/${lesson.id}${path}`, body)
    if (clearAfterSave) {
      submissionText.value = ''
      submissionFile.value = null
    }
    await loadSubmissions()
  } catch (e) {
    error.value = e.message
  } finally {
    submitting.value = false
  }
}
async function markLessonComplete() {
  completing.value = true
  try {
    await stopStudySession(true)
    await loadPlayer()
  } finally {
    completing.value = false
  }
}
function formatStudyTime(seconds) {
  const minutes = Math.floor(seconds / 60)
  return `${String(minutes).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`
}
function dateTimeText(value) {
  return value
    ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
    : '—'
}
function submissionStatus(value) {
  return (
    {
      SUBMITTED: 'Đã nộp',
      GRADED: 'Đã chấm',
      RETURNED: 'Yêu cầu nộp lại',
      DRAFT: 'Bản nháp'
    }[value] || value
  )
}
function mapCourseContent(data) {
  const chapterRows = pick(data, 'chapters', 'Chapters') || [],
    lessonRows = pick(data, 'lessons', 'Lessons') || []
  chapters.value = chapterRows.map((row) => {
    const id = Number(pick(row, 'Id', 'id'))
    return {
      id,
      title: pick(row, 'Title', 'title') || '',
      lessons: lessonRows
        .filter((x) => Number(pick(x, 'ChapterId', 'chapterId')) === id)
        .map((x) => ({
          id: Number(pick(x, 'Id', 'id')),
          title: pick(x, 'Title', 'title') || '',
          duration: Number(pick(x, 'DurationSeconds', 'durationSeconds') || 0),
          completed: Boolean(pick(x, 'Completed', 'completed'))
        }))
    }
  })
}
function handleProgress(value) {
  Object.assign(progress, value)
  if (progress.currentTime - lastSavedAt.value >= 10) void saveProgress()
}
async function saveProgress() {
  if (!video.id || savingProgress.value) return
  savingProgress.value = true
  try {
    await axiosClient.post('/lms/progress/video', {
      lessonId: lesson.id,
      videoId: video.id,
      currentTime: progress.currentTime,
      maxWatchedTime: progress.maxWatchedTime,
      watchPercent: progress.watchPercent
    })
    lastSavedAt.value = progress.currentTime
  } catch (e) {
    error.value = e.message
  } finally {
    savingProgress.value = false
  }
}
async function submitInteractionAnswer(item, answers) {
  return axiosClient.post('/lms/answers', {
    lessonId: lesson.id,
    videoId: video.id,
    interactionId: item.id,
    questionId: item.questionId,
    answers,
    timeInVideo: item.timeSeconds,
    timeSpent: 0
  })
}
function handleAnswered({ interaction, result }) {
  interaction.answered = true
  interaction.attempts = Number(pick(result, 'attemptNumber', 'AttemptNumber') || 1)
  currentScore.value = Number(
    pick(result, 'currentLessonScore', 'CurrentLessonScore') ||
      currentScore.value + Number(pick(result, 'scoreAwarded', 'ScoreAwarded') || 0)
  )
  void saveProgress()
}
</script>

<style scoped src="../../assets/css/pages/lms/lesson-player.css"></style>
