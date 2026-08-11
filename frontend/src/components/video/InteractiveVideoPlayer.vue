<template>
  <div class="interactive-player">
    <div class="interactive-stage">
      <video v-if="source" ref="videoRef" :src="source" :poster="poster || undefined" controls preload="metadata" :controlslist="allowSpeed ? undefined : 'noplaybackrate'" @loadedmetadata="onLoaded" @play="onPlay" @timeupdate="onTimeUpdate" @seeking="onSeeking" @seeked="onSeeked" @ratechange="onRateChange" @pause="emitProgress"><track kind="captions"></video>
      <div v-else class="interactive-empty"><i class="bi bi-camera-video-off"></i><strong>Video chưa sẵn sàng</strong><span>Chưa có file video để phát.</span></div>
      <button v-for="item in normalized" :key="item.id" type="button" class="interactive-marker" :class="{answered:item.answered}" :style="{left:markerPercent(item.timeSeconds)+'%'}" :title="`${formatTime(item.timeSeconds)} — ${item.label}`" @click="openQuestion(item)"></button>
    </div>

    <div v-if="activeQuestion" class="interaction-backdrop" @click.self="closeQuestion">
      <div class="interaction-modal app-card" role="dialog" aria-modal="true" :aria-label="activeQuestion.label">
        <button v-if="canSkip" class="interaction-close" type="button" aria-label="Đóng câu hỏi" @click="closeQuestion"><i class="bi bi-x-lg"></i></button>
        <span class="badge badge-soft-warning">Câu hỏi tại {{ formatTime(activeQuestion.timeSeconds) }}</span>
        <h2>{{ activeQuestion.label }}</h2>
        <p v-if="activeQuestion.description" class="text-secondary">{{ activeQuestion.description }}</p>
        <template v-if="!answerResult">
          <label v-for="option in activeQuestion.options" :key="option.code" class="interaction-answer"><input v-if="activeQuestion.type==='MULTIPLE_CHOICE'" v-model="multipleAnswers" type="checkbox" :value="option.code"><input v-else v-model="singleAnswer" type="radio" :value="option.code"><span>{{ option.code }}</span>{{ option.text }}</label>
          <textarea v-if="activeQuestion.type==='SHORT_ANSWER'" v-model.trim="shortAnswer" class="form-control" rows="4" placeholder="Nhập câu trả lời của bạn..."></textarea>
          <div v-if="answerError" class="alert alert-danger mt-3 mb-0">{{ answerError }}</div>
          <button class="btn btn-brand w-100 mt-3" :disabled="submitting||!hasAnswer" @click="submit"><span v-if="submitting" class="spinner-border spinner-border-sm me-1"></span>Gửi câu trả lời</button>
        </template>
        <div v-else class="interaction-result" :class="answerResult.isCorrect===true?'correct':answerResult.isCorrect===false?'wrong':'pending'"><i :class="['bi',answerResult.isCorrect===true?'bi-check-circle-fill':answerResult.isCorrect===false?'bi-x-circle-fill':'bi-hourglass-split']"></i><h3>{{ answerResult.isCorrect===true?'Chính xác!':answerResult.isCorrect===false?'Chưa chính xác':'Đang chờ giảng viên chấm' }}</h3><strong>+{{ answerResult.score }} điểm</strong><p v-if="answerResult.explanation">{{ answerResult.explanation }}</p><button class="btn btn-brand w-100 mt-2" @click="continuePlayback">Tiếp tục bài học</button></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed,onBeforeUnmount,ref,watch } from 'vue'
import { formatInteractionTime } from '../../utils/learningRules'
import { createInteractionEngine,normalizeInteractions } from '../../composables/useVideoInteractions'

const props=defineProps({source:{type:String,default:''},poster:{type:String,default:''},durationSeconds:{type:Number,default:0},interactions:{type:Array,default:()=>[]},answeredInteractionIds:{type:Array,default:()=>[]},previewMode:{type:Boolean,default:false},allowSeek:{type:Boolean,default:true},allowSpeed:{type:Boolean,default:true},initialTime:{type:Number,default:0},maxWatchedTime:{type:Number,default:0},resetKey:{type:[String,Number],default:0},onSubmitAnswer:{type:Function,required:true}})
const emit=defineEmits(['progress','answered'])
const videoRef=ref(null),activeQuestion=ref(null),singleAnswer=ref(''),multipleAnswers=ref([]),shortAnswer=ref(''),submitting=ref(false),answerError=ref(''),answerResult=ref(null),watchedMax=ref(props.maxWatchedTime),loaded=ref(false)
const normalized=computed(()=>normalizeInteractions(props.interactions))
let engine=createInteractionEngine(normalized.value,props.answeredInteractionIds)
const formatTime=formatInteractionTime
const canSkip=computed(()=>Boolean(activeQuestion.value?.allowSkip||!activeQuestion.value?.required))
const hasAnswer=computed(()=>activeQuestion.value?.type==='MULTIPLE_CHOICE'?multipleAnswers.value.length>0:activeQuestion.value?.type==='SHORT_ANSWER'?Boolean(shortAnswer.value):Boolean(singleAnswer.value))

watch(()=>props.resetKey,resetPlayer)
function resetEngine(at=0){engine=createInteractionEngine(normalized.value,props.answeredInteractionIds);engine.loadAt(at);activeQuestion.value=null;answerResult.value=null;answerError.value=''}
function resetPlayer(){const element=videoRef.value;element?.pause();watchedMax.value=props.maxWatchedTime;resetEngine(0);if(element){element.currentTime=0;element.playbackRate=1}}
function onLoaded(){loaded.value=true;const element=videoRef.value;if(!element)return;const duration=Number.isFinite(element.duration)?element.duration:props.durationSeconds;element.currentTime=Math.min(Math.max(0,props.initialTime),Math.max(0,duration-.25));engine.loadAt(element.currentTime);emitProgress()}
function activate(item){if(!item)return;videoRef.value?.pause();activeQuestion.value=item;singleAnswer.value='';multipleAnswers.value=[];shortAnswer.value='';answerError.value='';answerResult.value=null}
function onPlay(){if(!loaded.value)return;activate(engine.start(videoRef.value?.currentTime||0))}
function onTimeUpdate(){const element=videoRef.value;if(!element||!loaded.value)return;watchedMax.value=Math.max(watchedMax.value,element.currentTime);activate(engine.tick(element.currentTime));emitProgress()}
function onSeeking(){const element=videoRef.value;if(!element)return;engine.beginSeek();if(!props.previewMode&&!props.allowSeek&&element.currentTime>watchedMax.value+2)element.currentTime=watchedMax.value}
function onSeeked(){const element=videoRef.value;if(!element)return;engine.endSeek(element.currentTime);emitProgress()}
function onRateChange(){if(videoRef.value&&!props.allowSpeed)videoRef.value.playbackRate=1}
function emitProgress(){const element=videoRef.value;if(!element)return;const duration=props.durationSeconds||element.duration||0;emit('progress',{currentTime:element.currentTime,maxWatchedTime:watchedMax.value,watchPercent:duration?Math.min(100,watchedMax.value/duration*100):0})}
function openQuestion(item){activate(engine.open(item))}
function closeQuestion(){if(!canSkip.value||!engine.close())return;activeQuestion.value=null;void videoRef.value?.play()}
async function submit(){if(!activeQuestion.value||submitting.value)return;submitting.value=true;answerError.value='';try{const answers=activeQuestion.value.type==='MULTIPLE_CHOICE'?multipleAnswers.value:activeQuestion.value.type==='SHORT_ANSWER'?[shortAnswer.value]:[singleAnswer.value];const result=await props.onSubmitAnswer(activeQuestion.value,answers);answerResult.value={isCorrect:result?.isCorrect??result?.IsCorrect??null,score:Number(result?.score??result?.scoreAwarded??result?.ScoreAwarded??0),explanation:result?.explanation??result?.Explanation??''};activeQuestion.value.answered=true;activeQuestion.value.attempts=Number(result?.attemptNumber??result?.AttemptNumber??1);emit('answered',{interaction:activeQuestion.value,result})}catch(error){answerError.value=error?.message||'Không thể gửi câu trả lời. Vui lòng thử lại.'}finally{submitting.value=false}}
function continuePlayback(){const next=engine.continue();activeQuestion.value=null;answerResult.value=null;if(next)activate(next);else void videoRef.value?.play()}
function markerPercent(time){const duration=props.durationSeconds||videoRef.value?.duration||0;return duration?Math.min(100,time/duration*100):0}
function seekTo(time){if(!videoRef.value)return;videoRef.value.currentTime=Math.max(0,Number(time)||0)}
function play(){return videoRef.value?.play()}
function pause(){videoRef.value?.pause()}
onBeforeUnmount(()=>{videoRef.value?.pause();activeQuestion.value=null})
defineExpose({seekTo,play,pause,openQuestion,reset:resetPlayer,videoElement:videoRef})
</script>

<style scoped>
.interactive-player{height:100%}
.interactive-stage{height:100%;min-height:280px;background:#071922;position:relative;display:grid;place-items:center}.interactive-stage video{width:100%;height:100%;object-fit:contain;background:#000}.interactive-empty{display:grid;place-items:center;gap:.6rem;color:#d5e1dc}.interactive-empty i{font-size:3rem;color:#ffff1a}.interactive-empty span{color:#93a8a0;font-size:.82rem}.interactive-marker{position:absolute;bottom:49px;transform:translateX(-50%);width:15px;height:15px;border-radius:50%;border:2px solid white;background:#cd1b1b;box-shadow:0 2px 7px rgba(0,0,0,.3)}.interactive-marker.answered{background:#07875a}.interaction-backdrop{position:fixed;inset:0;background:rgba(10,31,24,.66);z-index:2000;display:grid;place-items:center;padding:1rem}.interaction-modal{width:min(590px,100%);padding:2rem;position:relative;max-height:92vh;overflow:auto}.interaction-modal h2{font-size:1.4rem;font-weight:750;margin-top:1rem}.interaction-close{position:absolute;right:1rem;top:1rem;border:0;background:#f3f6f5;width:34px;height:34px;border-radius:8px}.interaction-answer{display:flex;align-items:center;gap:.75rem;padding:.8rem;margin:.55rem 0;background:#f7f9f8;border-radius:9px}.interaction-answer>span{width:28px;height:28px;border-radius:7px;background:white;display:grid;place-items:center;font-weight:750}.interaction-result{text-align:center;padding-top:1rem}.interaction-result>i{font-size:3.5rem}.interaction-result.correct{color:#07875a}.interaction-result.wrong{color:#cd1b1b}.interaction-result.pending{color:#8a7000}.interaction-result h3{font-size:1.3rem;margin:.6rem 0}.interaction-result p{color:#53655f;margin-top:1rem}
</style>
