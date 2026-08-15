<template>
  <div class="interactive-player">
    <div class="interactive-stage">
      <video
        v-if="source"
        ref="videoRef"
        :src="source"
        :poster="poster || undefined"
        controls
        preload="metadata"
        :controlslist="allowSpeed ? undefined : 'noplaybackrate'"
        @loadedmetadata="onLoaded"
        @play="onPlay"
        @timeupdate="onTimeUpdate"
        @seeking="onSeeking"
        @seeked="onSeeked"
        @ratechange="onRateChange"
        @pause="emitProgress"
      >
        <track kind="captions" />
      </video>
      <div v-else class="interactive-empty">
        <i class="bi bi-camera-video-off"></i><strong>Video chưa sẵn sàng</strong
        ><span>Chưa có file video để phát.</span>
      </div>
    </div>

    <div v-if="source" class="interaction-timeline">
      <div
        class="interaction-track"
        :class="{ seekable: canTimelineSeek }"
        role="slider"
        :tabindex="canTimelineSeek ? 0 : -1"
        aria-label="Dòng thời gian câu hỏi tương tác"
        aria-valuemin="0"
        :aria-valuemax="effectiveDuration"
        :aria-valuenow="Math.round(currentTime)"
        @click="seekFromTimeline"
        @keydown.left.prevent="stepTimeline(-5)"
        @keydown.right.prevent="stepTimeline(5)"
      >
        <span class="interaction-track-progress" :style="{ width: currentPercent + '%' }"></span>
        <span class="interaction-playhead" :style="{ left: currentPercent + '%' }"></span>
        <button
          v-for="(item, index) in normalized"
          :key="item.id"
          type="button"
          class="timeline-question"
          :class="{ answered: item.answered, staggered: index % 2 === 1 }"
          :style="{ left: markerPercent(item.timeSeconds) + '%' }"
          :title="`${formatTime(item.timeSeconds)} — ${item.label}`"
          @click.stop="openQuestion(item)"
        >
          <i :class="['bi', item.answered ? 'bi-check-circle-fill' : 'bi-patch-question-fill']"></i
          ><span>{{ formatTime(item.timeSeconds) }}</span>
        </button>
      </div>
      <div class="timeline-current">
        <i class="bi bi-cursor-fill"></i> Đang xem <strong>{{ formatTime(currentTime) }}</strong>
      </div>
    </div>

    <div v-if="activeQuestion" class="interaction-backdrop" @click.self="closeQuestion">
      <div class="interaction-modal app-card" role="dialog" aria-modal="true" :aria-label="activeQuestion.label">
        <button v-if="canSkip" class="interaction-close" type="button" aria-label="Đóng câu hỏi" @click="closeQuestion">
          <i class="bi bi-x-lg"></i>
        </button>
        <span class="badge badge-soft-warning">Câu hỏi tại {{ formatTime(activeQuestion.timeSeconds) }}</span>
        <h2>{{ activeQuestion.label }}</h2>
        <p v-if="activeQuestion.description" class="text-secondary">{{ activeQuestion.description }}</p>
        <template v-if="!answerResult">
          <label v-for="option in activeQuestion.options" :key="option.code" class="interaction-answer"
            ><input
              v-if="activeQuestion.type === 'MULTIPLE_CHOICE'"
              v-model="multipleAnswers"
              type="checkbox"
              :value="option.code"
            /><input v-else v-model="singleAnswer" type="radio" :value="option.code" /><span>{{ option.code }}</span
            >{{ option.text }}</label
          >
          <textarea
            v-if="activeQuestion.type === 'SHORT_ANSWER'"
            v-model.trim="shortAnswer"
            class="form-control"
            rows="4"
            placeholder="Nhập câu trả lời của bạn..."
          ></textarea>
          <div v-if="answerError" class="alert alert-danger mt-3 mb-0">{{ answerError }}</div>
          <button class="btn btn-brand w-100 mt-3" :disabled="submitting || !hasAnswer" @click="submit">
            <span v-if="submitting" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-send"></i> Gửi câu trả lời
          </button>
        </template>
        <div
          v-else
          class="interaction-result"
          :class="answerResult.isCorrect === true ? 'correct' : answerResult.isCorrect === false ? 'wrong' : 'pending'"
        >
          <i
            :class="[
              'bi',
              answerResult.isCorrect === true
                ? 'bi-check-circle-fill'
                : answerResult.isCorrect === false
                  ? 'bi-x-circle-fill'
                  : 'bi-hourglass-split'
            ]"
          ></i>
          <h3>
            {{
              answerResult.isCorrect === true
                ? 'Chính xác!'
                : answerResult.isCorrect === false
                  ? 'Chưa chính xác'
                  : 'Đang chờ giảng viên chấm'
            }}
          </h3>
          <strong>+{{ answerResult.score }} điểm</strong>
          <p v-if="answerResult.explanation">{{ answerResult.explanation }}</p>
          <button class="btn btn-brand w-100 mt-2" @click="continuePlayback">
            Tiếp tục bài học <i class="bi bi-arrow-right"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { formatInteractionTime } from '../../utils/learningRules'
import { createInteractionEngine, normalizeInteractions } from '../../composables/useVideoInteractions'

const props = defineProps({
  source: { type: String, default: '' },
  poster: { type: String, default: '' },
  durationSeconds: { type: Number, default: 0 },
  interactions: { type: Array, default: () => [] },
  answeredInteractionIds: { type: Array, default: () => [] },
  previewMode: { type: Boolean, default: false },
  allowSeek: { type: Boolean, default: true },
  allowSpeed: { type: Boolean, default: true },
  initialTime: { type: Number, default: 0 },
  maxWatchedTime: { type: Number, default: 0 },
  resetKey: { type: [String, Number], default: 0 },
  onSubmitAnswer: { type: Function, required: true }
})
const emit = defineEmits(['progress', 'answered'])
const videoRef = ref(null),
  activeQuestion = ref(null),
  singleAnswer = ref(''),
  multipleAnswers = ref([]),
  shortAnswer = ref(''),
  submitting = ref(false),
  answerError = ref(''),
  answerResult = ref(null),
  watchedMax = ref(props.maxWatchedTime),
  loaded = ref(false),
  currentTime = ref(props.initialTime)
const normalized = computed(() => normalizeInteractions(props.interactions))
let engine = createInteractionEngine(normalized.value, props.answeredInteractionIds)
const formatTime = formatInteractionTime
const canSkip = computed(() => Boolean(activeQuestion.value?.allowSkip || !activeQuestion.value?.required))
const hasAnswer = computed(() =>
  activeQuestion.value?.type === 'MULTIPLE_CHOICE'
    ? multipleAnswers.value.length > 0
    : activeQuestion.value?.type === 'SHORT_ANSWER'
      ? Boolean(shortAnswer.value)
      : Boolean(singleAnswer.value)
)
const effectiveDuration = computed(() => props.durationSeconds || videoRef.value?.duration || 0)
const currentPercent = computed(() =>
  effectiveDuration.value ? Math.min(100, Math.max(0, (currentTime.value / effectiveDuration.value) * 100)) : 0
)
const canTimelineSeek = computed(() => props.previewMode || props.allowSeek)

watch(() => props.resetKey, resetPlayer)
function resetEngine(at = 0) {
  engine = createInteractionEngine(normalized.value, props.answeredInteractionIds)
  engine.loadAt(at)
  activeQuestion.value = null
  answerResult.value = null
  answerError.value = ''
}
function resetPlayer() {
  const element = videoRef.value
  element?.pause()
  watchedMax.value = props.maxWatchedTime
  currentTime.value = 0
  resetEngine(0)
  if (element) {
    element.currentTime = 0
    element.playbackRate = 1
  }
}
function onLoaded() {
  loaded.value = true
  const element = videoRef.value
  if (!element) return
  const duration = Number.isFinite(element.duration) ? element.duration : props.durationSeconds
  element.currentTime = Math.min(Math.max(0, props.initialTime), Math.max(0, duration - 0.25))
  currentTime.value = element.currentTime
  engine.loadAt(element.currentTime)
  emitProgress()
}
function activate(item) {
  if (!item) return
  videoRef.value?.pause()
  activeQuestion.value = item
  singleAnswer.value = ''
  multipleAnswers.value = []
  shortAnswer.value = ''
  answerError.value = ''
  answerResult.value = null
}
function onPlay() {
  if (!loaded.value) return
  activate(engine.start(videoRef.value?.currentTime || 0))
}
function onTimeUpdate() {
  const element = videoRef.value
  if (!element || !loaded.value) return
  currentTime.value = element.currentTime
  watchedMax.value = Math.max(watchedMax.value, element.currentTime)
  activate(engine.tick(element.currentTime))
  emitProgress()
}
function onSeeking() {
  const element = videoRef.value
  if (!element) return
  engine.beginSeek()
  if (!props.previewMode && !props.allowSeek && element.currentTime > watchedMax.value + 2)
    element.currentTime = watchedMax.value
}
function onSeeked() {
  const element = videoRef.value
  if (!element) return
  currentTime.value = element.currentTime
  engine.endSeek(element.currentTime)
  emitProgress()
}
function onRateChange() {
  if (videoRef.value && !props.allowSpeed) videoRef.value.playbackRate = 1
}
function emitProgress() {
  const element = videoRef.value
  if (!element) return
  const duration = props.durationSeconds || element.duration || 0
  emit('progress', {
    currentTime: element.currentTime,
    maxWatchedTime: watchedMax.value,
    watchPercent: duration ? Math.min(100, (watchedMax.value / duration) * 100) : 0
  })
}
function openQuestion(item) {
  activate(engine.open(item))
}
function closeQuestion() {
  if (!canSkip.value || !engine.close()) return
  activeQuestion.value = null
  void videoRef.value?.play()
}
async function submit() {
  if (!activeQuestion.value || submitting.value) return
  submitting.value = true
  answerError.value = ''
  try {
    const answers =
      activeQuestion.value.type === 'MULTIPLE_CHOICE'
        ? multipleAnswers.value
        : activeQuestion.value.type === 'SHORT_ANSWER'
          ? [shortAnswer.value]
          : [singleAnswer.value]
    const result = await props.onSubmitAnswer(activeQuestion.value, answers)
    answerResult.value = {
      isCorrect: result?.isCorrect ?? result?.IsCorrect ?? null,
      score: Number(result?.score ?? result?.scoreAwarded ?? result?.ScoreAwarded ?? 0),
      explanation: result?.explanation ?? result?.Explanation ?? ''
    }
    activeQuestion.value.answered = true
    activeQuestion.value.attempts = Number(result?.attemptNumber ?? result?.AttemptNumber ?? 1)
    emit('answered', { interaction: activeQuestion.value, result })
  } catch (error) {
    answerError.value = error?.message || 'Không thể gửi câu trả lời. Vui lòng thử lại.'
  } finally {
    submitting.value = false
  }
}
function continuePlayback() {
  const next = engine.continue()
  activeQuestion.value = null
  answerResult.value = null
  if (next) activate(next)
  else void videoRef.value?.play()
}
function markerPercent(time) {
  return effectiveDuration.value ? Math.min(99, Math.max(1, (time / effectiveDuration.value) * 100)) : 0
}
function seekTo(time) {
  if (!videoRef.value) return
  const target = Math.min(effectiveDuration.value, Math.max(0, Number(time) || 0))
  currentTime.value = target
  videoRef.value.currentTime = target
}
function seekFromTimeline(event) {
  if (!canTimelineSeek.value) return
  const rect = event.currentTarget.getBoundingClientRect()
  if (!rect.width) return
  seekTo(((event.clientX - rect.left) / rect.width) * effectiveDuration.value)
}
function stepTimeline(seconds) {
  if (canTimelineSeek.value) seekTo(currentTime.value + seconds)
}
function play() {
  return videoRef.value?.play()
}
function pause() {
  videoRef.value?.pause()
}
onBeforeUnmount(() => {
  videoRef.value?.pause()
  activeQuestion.value = null
})
defineExpose({ seekTo, play, pause, openQuestion, reset: resetPlayer, videoElement: videoRef })
</script>

<style scoped src="../../assets/css/components/interactive-video-player.css"></style>
