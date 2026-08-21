<template>
  <div :class="['interactive-player', { 'youtube-mode': isYouTube, 'mobile-inline': inlineInteractivePlayback }]">
    <div class="interactive-stage">
      <YouTubeVideoPlayer
        v-if="source && isYouTube"
        ref="youtubeRef"
        :source="source"
        :initial-time="initialTime"
        @ready="onYouTubeReady"
        @play="onYouTubePlay"
        @pause="emitProgress"
        @timeupdate="onYouTubeTimeUpdate"
      />
      <video
        v-else-if="source"
        ref="videoRef"
        :src="source"
        :poster="poster || undefined"
        controls
        preload="metadata"
        :playsinline="inlineInteractivePlayback"
        :webkit-playsinline="inlineInteractivePlayback ? '' : undefined"
        :controlslist="videoControlsList"
        :disablepictureinpicture="mobileInlinePlayback"
        :disableremoteplayback="mobileInlinePlayback"
        @loadedmetadata="onLoaded"
        @play="onPlay"
        @timeupdate="onTimeUpdate"
        @seeking="onSeeking"
        @seeked="onSeeked"
        @ratechange="onRateChange"
        @pause="emitProgress"
        @webkitbeginfullscreen="preventNativeFullscreen"
        @fullscreenchange="preventStandardVideoFullscreen"
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

    <div
      v-if="activeQuestion"
      :class="isYouTube ? 'youtube-interaction-host' : 'interaction-backdrop'"
      @click.self="closeQuestion"
    >
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
          <div v-if="choiceQuestionWithoutOptions" class="alert alert-warning interaction-options-warning mt-3 mb-0">
            <i class="bi bi-exclamation-triangle me-2"></i>Câu hỏi chưa có phương án trả lời. Vui lòng kiểm tra lại
            trong ngân hàng câu hỏi.
          </div>
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
import YouTubeVideoPlayer from './YouTubeVideoPlayer.vue'
import { formatInteractionTime } from '../../utils/learningRules'
import { createInteractionEngine, normalizeInteractions } from '../../composables/useVideoInteractions'
import { isYouTubeSource } from '../../utils/videoSources'

const props = defineProps({
  source: { type: String, default: '' },
  sourceType: { type: String, default: 'LOCAL' },
  interactiveMode: { type: Boolean, default: true },
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
  youtubeRef = ref(null),
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
const isYouTube = computed(() => isYouTubeSource(props.sourceType))
const inlineInteractivePlayback = computed(() => props.interactiveMode)
const mobileInlinePlayback = computed(() => props.interactiveMode && isMobilePlaybackEnvironment())
const videoControlsList = computed(
  () =>
    [!props.allowSpeed ? 'noplaybackrate' : '', mobileInlinePlayback.value ? 'nofullscreen noremoteplayback' : '']
      .filter(Boolean)
      .join(' ') || undefined
)
let engine = createInteractionEngine(normalized.value, props.answeredInteractionIds)
const formatTime = formatInteractionTime
const canSkip = computed(() => Boolean(activeQuestion.value?.allowSkip || !activeQuestion.value?.required))
const choiceQuestionWithoutOptions = computed(
  () =>
    ['SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'TRUE_FALSE'].includes(activeQuestion.value?.type) &&
    !activeQuestion.value?.options?.length
)
const hasAnswer = computed(() =>
  activeQuestion.value?.type === 'MULTIPLE_CHOICE'
    ? multipleAnswers.value.length > 0
    : activeQuestion.value?.type === 'SHORT_ANSWER'
      ? Boolean(shortAnswer.value)
      : Boolean(singleAnswer.value)
)
const effectiveDuration = computed(
  () => props.durationSeconds || youtubeRef.value?.getDuration?.() || videoRef.value?.duration || 0
)
const currentPercent = computed(() =>
  effectiveDuration.value ? Math.min(100, Math.max(0, (currentTime.value / effectiveDuration.value) * 100)) : 0
)
const canTimelineSeek = computed(() => props.previewMode || props.allowSeek)

watch(() => props.resetKey, resetPlayer)
watch(videoRef, configureInlinePlayback, { flush: 'post' })
function isMobilePlaybackEnvironment() {
  if (typeof window === 'undefined' || typeof navigator === 'undefined') return false
  return (
    /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
    window.matchMedia?.('(hover: none) and (pointer: coarse)')?.matches
  )
}
function configureInlinePlayback(element) {
  if (!element || !inlineInteractivePlayback.value) return
  element.playsInline = true
  element.setAttribute('playsinline', '')
  element.setAttribute('webkit-playsinline', '')
  if (videoControlsList.value) element.setAttribute('controlslist', videoControlsList.value)
  else element.removeAttribute('controlslist')
  if (mobileInlinePlayback.value) {
    element.disablePictureInPicture = true
    element.disableRemotePlayback = true
  }
}
function preventNativeFullscreen(event) {
  if (!inlineInteractivePlayback.value) return
  const element = event.currentTarget
  configureInlinePlayback(element)
  element.pause()
  try {
    element.webkitExitFullscreen?.()
  } catch {
    // Safari cũ có thể phát sự kiện trước khi trạng thái fullscreen hoàn tất.
  }
}
function preventStandardVideoFullscreen() {
  if (!mobileInlinePlayback.value || document.fullscreenElement !== videoRef.value) return
  const exitRequest = document.exitFullscreen?.()
  exitRequest?.catch?.(() => {})
}
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
  youtubeRef.value?.pause?.()
  watchedMax.value = props.maxWatchedTime
  currentTime.value = 0
  resetEngine(0)
  if (element) {
    element.currentTime = 0
    element.playbackRate = 1
  }
  youtubeRef.value?.seekTo?.(0, true)
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
  youtubeRef.value?.pause?.()
  activeQuestion.value = item
  singleAnswer.value = ''
  multipleAnswers.value = []
  shortAnswer.value = ''
  answerError.value = ''
  answerResult.value = null
}
function onYouTubeReady({ currentTime: time = props.initialTime }) {
  loaded.value = true
  currentTime.value = time
  engine.loadAt(time)
  emitProgress()
}
function onYouTubePlay({ currentTime: time = 0 }) {
  if (!loaded.value) return
  activate(engine.start(time))
}
function onYouTubeTimeUpdate({ currentTime: time = 0 }) {
  if (!loaded.value) return
  currentTime.value = time
  watchedMax.value = Math.max(watchedMax.value, time)
  activate(engine.tick(time))
  emitProgress()
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
  const time = isYouTube.value ? youtubeRef.value?.getCurrentTime?.() || currentTime.value : element?.currentTime
  if (time === undefined) return
  const duration = effectiveDuration.value
  emit('progress', {
    currentTime: time,
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
  play()
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
  else play()
}
function markerPercent(time) {
  return effectiveDuration.value ? Math.min(99, Math.max(1, (time / effectiveDuration.value) * 100)) : 0
}
function seekTo(time) {
  const target = Math.min(effectiveDuration.value, Math.max(0, Number(time) || 0))
  currentTime.value = target
  if (isYouTube.value) youtubeRef.value?.seekTo?.(target)
  else if (videoRef.value) videoRef.value.currentTime = target
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
  return isYouTube.value ? youtubeRef.value?.play?.() : videoRef.value?.play()
}
function pause() {
  if (isYouTube.value) youtubeRef.value?.pause?.()
  else videoRef.value?.pause()
}
onBeforeUnmount(() => {
  videoRef.value?.pause()
  youtubeRef.value?.pause?.()
  activeQuestion.value = null
})
defineExpose({
  seekTo,
  play,
  pause,
  openQuestion,
  reset: resetPlayer,
  videoElement: videoRef,
  youtubePlayer: youtubeRef
})
</script>

<style scoped src="../../assets/css/components/interactive-video-player.css"></style>
