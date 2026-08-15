<template>
  <section>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <RouterLink :to="`/lms/courses/${course.id}`"><i class="bi bi-arrow-left me-1"></i>Quay lại khóa học</RouterLink
      ><span class="badge badge-soft-success">Đã xem {{ Math.round(progress.watchPercent) }}%</span>
    </div>
    <div v-if="loading" class="app-card p-5 text-center">
      <span class="spinner-border text-success"></span>
      <p class="text-secondary mt-3 mb-0">Đang tải bài học...</p>
    </div>
    <div v-else-if="error" class="app-card p-5 text-center">
      <i class="bi bi-exclamation-circle fs-1 text-danger"></i>
      <h1 class="h4 mt-3">Không thể mở bài học</h1>
      <p class="text-secondary">{{ error }}</p>
      <button class="btn btn-brand" @click="loadPlayer">Thử lại</button>
    </div>
    <template v-else>
      <div class="player-grid app-card overflow-hidden">
        <div class="video-area">
          <div class="video-stage">
            <InteractiveVideoPlayer
              ref="playerRef"
              :key="playerKey"
              :source="video.url"
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
            <strong>Nội dung khóa học</strong
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
      <div class="app-card p-4 mt-4">
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
              ><small>{{ item.type }} • {{ item.score }} điểm</small>
            </div>
          </button>
        </div>
        <p v-else class="text-secondary mb-0">Bài học này không có câu hỏi tương tác.</p>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { formatInteractionTime } from '../../utils/learningRules'
import InteractiveVideoPlayer from '../../components/video/InteractiveVideoPlayer.vue'

const route = useRoute(),
  playerRef = ref(null),
  loading = ref(true),
  error = ref(''),
  interactions = ref([]),
  chapters = ref([]),
  answeredInteractionIds = ref([]),
  playerKey = ref(0)
const lesson = reactive({ id: 0, title: '', description: '', type: 'VIDEO', duration: 0, passingScore: 0 }),
  course = reactive({ id: 0, title: '' }),
  video = reactive({
    id: 0,
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
  completedLessons = computed(() =>
    chapters.value.reduce((total, chapter) => total + chapter.lessons.filter((x) => x.completed).length, 0)
  )
onMounted(loadPlayer)
onBeforeUnmount(() => {
  playerRef.value?.pause()
  void saveProgress()
})
watch(
  () => route.params.lessonId,
  () => {
    playerRef.value?.pause()
    void saveProgress().finally(loadPlayer)
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
      passingScore: Number(pick(l, 'PassingScore', 'passingScore') || 0)
    })
    Object.assign(course, { id: Number(pick(c, 'Id', 'id')), title: pick(c, 'Title', 'title') || '' })
    Object.assign(video, {
      id: Number(pick(v, 'Id', 'id') || 0),
      url: resolveApiAssetUrl(pick(v, 'VideoUrl', 'videoUrl') || ''),
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
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
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
