<template>
  <section ref="viewerRoot" class="interactive-content-viewer">
    <div v-if="loading" class="interactive-loading">
      <span class="spinner-border"></span> Đang tải bài học tương tác...
    </div>
    <div v-else-if="error" class="interactive-error"><i class="bi bi-exclamation-circle"></i> {{ error }}</div>
    <template v-else>
      <div class="interactive-content-layout">
        <main>
          <article class="interactive-reading-content" v-html="safeContent"></article>
          <section class="inline-questions">
            <header>
              <span>CÂU HỎI ĐỌC HIỂU</span>
              <h2>Kiểm tra mức độ hiểu bài</h2>
              <p>Trả lời ngay trong lúc học. Mỗi kết quả được lưu để bạn có thể tiếp tục sau khi tải lại trang.</p>
            </header>
            <article
              v-for="(question, index) in questions"
              :id="`content-question-${question.id}`"
              :key="question.id"
              :ref="(element) => setQuestionRef(question.id, element)"
              :class="['inline-question-card', { active: activeQuestionId === question.id }]"
            >
              <div class="question-heading">
                <span>Câu {{ String(index + 1).padStart(2, '0') }}</span>
                <div>
                  <strong>{{ question.text }}</strong>
                  <small>{{ question.required ? 'Bắt buộc' : 'Không bắt buộc' }} · {{ question.score }} điểm</small>
                </div>
              </div>
              <div v-if="question.type === 'MULTIPLE_CHOICE'" class="content-answer-options">
                <label v-for="option in question.options" :key="option.code">
                  <input
                    v-model="draftAnswers[question.id]"
                    type="checkbox"
                    :value="option.code"
                    :disabled="!canAnswer(question)"
                  />
                  <span
                    ><b>{{ option.code }}</b
                    >{{ option.text }}</span
                  >
                </label>
              </div>
              <div v-else-if="['SINGLE_CHOICE', 'TRUE_FALSE'].includes(question.type)" class="content-answer-options">
                <label v-for="option in question.options" :key="option.code">
                  <input
                    v-model="draftAnswers[question.id]"
                    type="radio"
                    :name="`content-question-${question.id}`"
                    :value="option.code"
                    :disabled="!canAnswer(question)"
                  />
                  <span
                    ><b>{{ option.code }}</b
                    >{{ option.text }}</span
                  >
                </label>
              </div>
              <textarea
                v-else
                v-model.trim="draftAnswers[question.id]"
                class="form-control"
                rows="3"
                :disabled="!canAnswer(question)"
                placeholder="Nhập câu trả lời của bạn..."
              ></textarea>
              <div
                v-if="question.resultVisible"
                :class="['content-answer-result', question.isCorrect ? 'correct' : 'incorrect']"
              >
                <i :class="['bi', question.isCorrect ? 'bi-check-circle-fill' : 'bi-x-circle-fill']"></i>
                <div>
                  <strong>{{ question.isCorrect ? 'Chính xác' : 'Chưa chính xác' }}</strong>
                  <p v-if="question.explanation">{{ question.explanation }}</p>
                </div>
              </div>
              <div class="question-actions">
                <span v-if="question.answered"><i class="bi bi-cloud-check"></i> Đáp án đã được lưu</span>
                <button
                  v-if="!question.answered"
                  class="btn btn-action-save"
                  type="button"
                  :disabled="busyQuestionId === question.id || !hasDraft(question) || !canAnswer(question)"
                  @click="submitAnswer(question)"
                >
                  <span v-if="busyQuestionId === question.id" class="spinner-border spinner-border-sm"></span>
                  <i v-else class="bi bi-send-check"></i>
                  Kiểm tra đáp án
                </button>
              </div>
            </article>
          </section>
          <section class="interactive-completion-card">
            <div>
              <span>KẾT QUẢ BÀI HỌC</span>
              <h2>{{ answeredCount }}/{{ questions.length }} câu đã trả lời</h2>
              <p>Tiến độ câu hỏi {{ answerProgress }}% · Tiến độ đọc {{ Math.round(progress.readingProgress) }}%</p>
              <strong v-if="settings.showScore">Điểm hiện tại: {{ progress.score }}%</strong>
              <p v-if="completionMessage || completionBlocker" :class="{ success: progress.completed }">
                {{ completionMessage || completionBlocker }}
              </p>
              <div v-if="unansweredRequired.length" class="unanswered-links">
                <span>Bạn còn câu bắt buộc:</span>
                <button
                  v-for="question in unansweredRequired"
                  :key="question.id"
                  type="button"
                  @click="goToQuestion(question.id)"
                >
                  Câu {{ question.index + 1 }}
                </button>
              </div>
            </div>
            <button
              class="btn btn-action-save"
              type="button"
              :disabled="completing || progress.completed || !completionReady"
              @click="completeLesson"
            >
              <i :class="['bi', progress.completed ? 'bi-check-circle-fill' : 'bi-check2-circle']"></i>
              {{ progress.completed ? 'Đã hoàn thành' : 'Hoàn thành bài học' }}
            </button>
          </section>
        </main>
        <aside class="interactive-question-sidebar">
          <div class="question-sidebar-heading">
            <div>
              <span>CÂU HỎI</span><strong>{{ answeredCount }}/{{ questions.length }} đã trả lời</strong>
            </div>
            <span>{{ answerProgress }}%</span>
          </div>
          <div class="question-progress-track"><i :style="{ width: `${answerProgress}%` }"></i></div>
          <button
            v-for="(question, index) in questions"
            :key="question.id"
            type="button"
            :class="questionStatusClass(question)"
            @click="goToQuestion(question.id)"
          >
            <span>{{ String(index + 1).padStart(2, '0') }}</span>
            <div>
              <strong>{{ question.text }}</strong
              ><small>{{ questionStatusText(question) }}</small>
            </div>
            <i :class="questionStatusIcon(question)"></i>
          </button>
        </aside>
      </div>
      <button class="mobile-question-button" type="button" @click="mobileSidebarOpen = !mobileSidebarOpen">
        <i class="bi bi-list-check"></i> Câu hỏi {{ answeredCount }}/{{ questions.length }}
      </button>
      <div v-if="mobileSidebarOpen" class="mobile-question-sheet" @click.self="mobileSidebarOpen = false">
        <div>
          <header>
            <strong>Danh sách câu hỏi</strong
            ><button type="button" @click="mobileSidebarOpen = false"><i class="bi bi-x-lg"></i></button>
          </header>
          <button
            v-for="(question, index) in questions"
            :key="question.id"
            type="button"
            :class="questionStatusClass(question)"
            @click="selectMobileQuestion(question.id)"
          >
            <span>{{ String(index + 1).padStart(2, '0') }}</span
            ><strong>{{ question.text }}</strong
            ><i :class="questionStatusIcon(question)"></i>
          </button>
        </div>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import axiosClient from '../../api/axiosClient'
import { sanitizeLearningHtml } from '../../utils/sanitizeHtml'

const props = defineProps({ lessonId: { type: Number, required: true } })
const emit = defineEmits(['completed', 'score-change'])
const loading = ref(true)
const error = ref('')
const questions = ref([])
const viewerRoot = ref(null)
const activeQuestionId = ref(0)
const busyQuestionId = ref(0)
const completing = ref(false)
const completionMessage = ref('')
const mobileSidebarOpen = ref(false)
const questionRefs = new Map()
const draftAnswers = reactive({})
const settings = reactive({
  contentHtml: '',
  completionRule: 'REQUIRED_QUESTIONS',
  requireReading: true,
  passingScore: 70,
  showResultImmediately: true,
  showScore: true
})
const progress = reactive({ readingProgress: 0, lastScroll: 0, score: 0, completed: false })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const safeContent = computed(() => sanitizeLearningHtml(settings.contentHtml || '<p>Bài học chưa có nội dung.</p>'))
const answeredCount = computed(() => questions.value.filter((question) => question.answered).length)
const answerProgress = computed(() =>
  questions.value.length ? Math.round((answeredCount.value * 100) / questions.value.length) : 100
)
const unansweredRequired = computed(() =>
  questions.value
    .map((question, index) => ({ ...question, index }))
    .filter((question) => question.required && !question.answered)
)
const completionReady = computed(() => {
  if (settings.requireReading && progress.readingProgress < 100) return false
  if (settings.completionRule === 'ALL_QUESTIONS') return answeredCount.value === questions.value.length
  if (settings.completionRule === 'PASSING_SCORE')
    return settings.showScore ? progress.score >= settings.passingScore : answeredCount.value === questions.value.length
  return unansweredRequired.value.length === 0
})
const completionBlocker = computed(() => {
  if (progress.completed) return ''
  if (settings.requireReading && progress.readingProgress < 100)
    return `Hãy đọc hết bài học (hiện tại ${Math.round(progress.readingProgress)}%).`
  if (settings.completionRule === 'ALL_QUESTIONS' && answeredCount.value < questions.value.length)
    return `Bạn còn ${questions.value.length - answeredCount.value} câu hỏi chưa trả lời.`
  if (
    settings.completionRule === 'PASSING_SCORE' &&
    !settings.showScore &&
    answeredCount.value < questions.value.length
  )
    return `Bạn còn ${questions.value.length - answeredCount.value} câu hỏi chưa trả lời.`
  if (settings.completionRule === 'PASSING_SCORE' && progress.score < settings.passingScore)
    return `Bạn cần đạt tối thiểu ${settings.passingScore}% để hoàn thành bài học.`
  if (unansweredRequired.value.length)
    return `Bạn còn ${unansweredRequired.value.length} câu hỏi bắt buộc chưa hoàn thành.`
  return ''
})
let scrollTimer

onMounted(load)
onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleScroll)
  clearTimeout(scrollTimer)
  void saveReadingProgress()
})
watch(() => props.lessonId, load)

async function load() {
  loading.value = true
  error.value = ''
  completionMessage.value = ''
  window.removeEventListener('scroll', handleScroll)
  try {
    const data = await axiosClient.get(`/lms/lessons/${props.lessonId}/interactive-content`, {
      params: { _fresh: Date.now() }
    })
    const lesson = pick(data, 'Lesson', 'lesson') || {}
    const answerRows = pick(data, 'Answers', 'answers') || []
    const answerMap = new Map(
      answerRows.map((row) => [Number(pick(row, 'ContentInteractionID', 'contentInteractionID')), row])
    )
    Object.assign(settings, {
      contentHtml: pick(lesson, 'ContentHtml', 'contentHtml') || '',
      completionRule: pick(lesson, 'CompletionRule', 'completionRule') || 'REQUIRED_QUESTIONS',
      requireReading: Boolean(pick(lesson, 'RequireReading', 'requireReading')),
      passingScore: Number(pick(lesson, 'PassingScore', 'passingScore') || 0),
      showResultImmediately: Boolean(pick(lesson, 'ShowResultImmediately', 'showResultImmediately')),
      showScore: Boolean(pick(lesson, 'ShowScore', 'showScore'))
    })
    questions.value = (pick(data, 'Interactions', 'interactions') || []).map((row, index) => {
      const id = Number(pick(row, 'ContentInteractionID', 'contentInteractionID'))
      const answer = answerMap.get(id)
      const type = pick(row, 'QuestionType', 'questionType') || 'SINGLE_CHOICE'
      const answerText = pick(answer, 'AnswerText', 'answerText') || ''
      draftAnswers[id] = type === 'MULTIPLE_CHOICE' ? answerText.split('|').filter(Boolean) : answerText
      return {
        id,
        questionId: Number(pick(row, 'QuestionID', 'questionID')),
        type,
        text: pick(row, 'QuestionText', 'questionText') || `Câu hỏi ${index + 1}`,
        required: Boolean(pick(row, 'Required', 'required')),
        score: Number(pick(row, 'Score', 'score') || 0),
        answered: Boolean(answer),
        isCorrect: pick(answer, 'IsCorrect', 'isCorrect'),
        resultVisible:
          pick(answer, 'IsCorrect', 'isCorrect') !== undefined && pick(answer, 'IsCorrect', 'isCorrect') !== null,
        explanation: pick(answer, 'Explanation', 'explanation') || '',
        options: parseOptions(pick(row, 'Options', 'options'))
      }
    })
    const savedProgress = pick(data, 'Progress', 'progress') || {}
    Object.assign(progress, {
      readingProgress: Number(pick(savedProgress, 'ReadingProgressPercent', 'readingProgressPercent') || 0),
      lastScroll: Number(pick(savedProgress, 'LastScrollPercent', 'lastScrollPercent') || 0),
      score: Number(pick(savedProgress, 'Score', 'score') || 0),
      completed: Boolean(pick(savedProgress, 'Completed', 'completed'))
    })
    activeQuestionId.value = questions.value.find((question) => !question.answered)?.id || questions.value[0]?.id || 0
    await nextTick()
    restoreReadingPosition()
    window.addEventListener('scroll', handleScroll, { passive: true })
  } catch (exception) {
    error.value = exception.message
  } finally {
    loading.value = false
  }
}

function parseOptions(value) {
  const rows = typeof value === 'string' ? JSON.parse(value || '[]') : value || []
  return rows.map((row) => ({
    code: pick(row, 'OptionCode', 'optionCode'),
    text: pick(row, 'OptionText', 'optionText')
  }))
}
function setQuestionRef(id, element) {
  if (element) questionRefs.set(id, element)
  else questionRefs.delete(id)
}
function goToQuestion(id) {
  activeQuestionId.value = id
  questionRefs.get(id)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
}
function selectMobileQuestion(id) {
  goToQuestion(id)
  mobileSidebarOpen.value = false
}
function canAnswer(question) {
  return !question.answered
}
function hasDraft(question) {
  const value = draftAnswers[question.id]
  return Array.isArray(value) ? value.length > 0 : Boolean(String(value || '').trim())
}
async function submitAnswer(question) {
  busyQuestionId.value = question.id
  completionMessage.value = ''
  try {
    const value = draftAnswers[question.id]
    const result = await axiosClient.post(`/lms/lessons/${props.lessonId}/interactive-content/answers`, {
      contentInteractionId: question.id,
      questionId: question.questionId,
      answers: Array.isArray(value) ? value : [value],
      timeSpentSeconds: null
    })
    question.answered = true
    question.isCorrect = pick(result, 'IsCorrect', 'isCorrect')
    question.resultVisible = question.isCorrect !== undefined && question.isCorrect !== null
    question.explanation = pick(result, 'Explanation', 'explanation') || ''
    progress.score = Number(pick(result, 'CurrentLessonScore', 'currentLessonScore') || 0)
    emit('score-change', progress.score)
  } catch (exception) {
    completionMessage.value = exception.message
  } finally {
    busyQuestionId.value = 0
  }
}
function questionStatusClass(question) {
  return {
    active: activeQuestionId.value === question.id,
    answered: question.answered,
    correct: question.resultVisible && question.isCorrect,
    incorrect: question.resultVisible && question.isCorrect === false
  }
}
function questionStatusText(question) {
  if (question.resultVisible) return question.isCorrect ? 'Đúng' : 'Chưa chính xác'
  return question.answered ? 'Đã trả lời' : activeQuestionId.value === question.id ? 'Đang chọn' : 'Chưa trả lời'
}
function questionStatusIcon(question) {
  if (question.resultVisible) return ['bi', question.isCorrect ? 'bi-check-circle-fill' : 'bi-x-circle-fill']
  return [
    'bi',
    question.answered ? 'bi-check-circle' : activeQuestionId.value === question.id ? 'bi-record-circle' : 'bi-circle'
  ]
}
function handleScroll() {
  clearTimeout(scrollTimer)
  scrollTimer = setTimeout(saveReadingProgress, 500)
}
async function saveReadingProgress() {
  const root = viewerRoot.value
  if (!root || loading.value) return
  const start = root.offsetTop
  const range = Math.max(1, root.scrollHeight - window.innerHeight)
  const percent = Math.min(100, Math.max(0, ((window.scrollY - start + window.innerHeight) / range) * 100))
  const lastScrollPercent = Math.min(100, Math.max(0, ((window.scrollY - start) / range) * 100))
  progress.readingProgress = Math.max(progress.readingProgress, percent)
  progress.lastScroll = lastScrollPercent
  try {
    await axiosClient.put(`/lms/lessons/${props.lessonId}/interactive-content/reading-progress`, {
      readingProgressPercent: progress.readingProgress,
      lastScrollPercent
    })
  } catch {
    // Tiến độ sẽ được thử lưu lại ở lần cuộn tiếp theo hoặc khi rời trang.
  }
}
function restoreReadingPosition() {
  if (!progress.lastScroll || !viewerRoot.value) return
  const range = Math.max(1, viewerRoot.value.scrollHeight - window.innerHeight)
  window.scrollTo({ top: viewerRoot.value.offsetTop + (range * progress.lastScroll) / 100, behavior: 'smooth' })
}
async function completeLesson() {
  completing.value = true
  completionMessage.value = ''
  try {
    await saveReadingProgress()
    const result = await axiosClient.post(`/lms/lessons/${props.lessonId}/interactive-content/complete`)
    progress.completed = Boolean(pick(result, 'Completed', 'completed'))
    progress.score = Number(pick(result, 'Score', 'score') || progress.score)
    completionMessage.value =
      pick(result, 'BlockReason', 'blockReason') ||
      (progress.completed ? 'Bạn đã hoàn thành bài học tương tác.' : 'Chưa đạt điều kiện hoàn thành.')
    if (progress.completed) emit('completed')
  } catch (exception) {
    completionMessage.value = exception.message
  } finally {
    completing.value = false
  }
}
</script>

<style scoped src="../../assets/css/components/interactive-content-viewer.css"></style>
