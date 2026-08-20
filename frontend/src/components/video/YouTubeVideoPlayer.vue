<template>
  <div class="youtube-player-shell">
    <div v-if="videoId" ref="hostRef" class="youtube-player-host"></div>
    <div v-else class="youtube-player-error">
      <i class="bi bi-youtube"></i><span>Liên kết YouTube chưa hợp lệ.</span>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { extractYouTubeVideoId } from '../../utils/videoSources'

const props = defineProps({ source: { type: String, default: '' }, initialTime: { type: Number, default: 0 } })
const emit = defineEmits(['ready', 'play', 'pause', 'timeupdate', 'ended', 'error'])
const hostRef = ref(null)
const videoId = computed(() => extractYouTubeVideoId(props.source))
let player = null
let timer = 0

function loadApi() {
  if (window.YT?.Player) return Promise.resolve(window.YT)
  if (window.__lmsYouTubeApiPromise) return window.__lmsYouTubeApiPromise
  window.__lmsYouTubeApiPromise = new Promise((resolve, reject) => {
    const previous = window.onYouTubeIframeAPIReady
    window.onYouTubeIframeAPIReady = () => {
      previous?.()
      resolve(window.YT)
    }
    const script = document.createElement('script')
    script.src = 'https://www.youtube.com/iframe_api'
    script.async = true
    script.onerror = () => reject(new Error('Không tải được trình phát YouTube.'))
    document.head.appendChild(script)
  })
  return window.__lmsYouTubeApiPromise
}

function snapshot() {
  return {
    currentTime: Number(player?.getCurrentTime?.() || 0),
    duration: Number(player?.getDuration?.() || 0)
  }
}

function startTimer() {
  stopTimer()
  timer = window.setInterval(() => emit('timeupdate', snapshot()), 250)
}

function stopTimer() {
  if (timer) window.clearInterval(timer)
  timer = 0
}

async function createPlayer() {
  if (!videoId.value || !hostRef.value) return
  try {
    const YT = await loadApi()
    player?.destroy?.()
    player = new YT.Player(hostRef.value, {
      videoId: videoId.value,
      playerVars: { enablejsapi: 1, origin: window.location.origin, playsinline: 1, rel: 0 },
      events: {
        onReady: () => {
          if (props.initialTime > 0) player.seekTo(props.initialTime, true)
          emit('ready', snapshot())
        },
        onStateChange: ({ data }) => {
          if (data === YT.PlayerState.PLAYING) {
            startTimer()
            emit('play', snapshot())
          } else {
            stopTimer()
            emit('timeupdate', snapshot())
            if (data === YT.PlayerState.PAUSED) emit('pause', snapshot())
            if (data === YT.PlayerState.ENDED) emit('ended', snapshot())
          }
        },
        onError: ({ data }) => emit('error', data)
      }
    })
  } catch (error) {
    emit('error', error)
  }
}

function play() {
  player?.playVideo?.()
}
function pause() {
  player?.pauseVideo?.()
}
function seekTo(value, shouldPause = false) {
  player?.seekTo?.(Math.max(0, Number(value) || 0), true)
  if (shouldPause) pause()
}
function getCurrentTime() {
  return snapshot().currentTime
}
function getDuration() {
  return snapshot().duration
}

onMounted(createPlayer)
watch(videoId, createPlayer)
onBeforeUnmount(() => {
  stopTimer()
  player?.destroy?.()
  player = null
})
defineExpose({ play, pause, seekTo, getCurrentTime, getDuration })
</script>

<style scoped src="../../assets/css/components/youtube-video-player.css"></style>
