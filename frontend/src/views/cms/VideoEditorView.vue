<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div><h1 class="page-title mb-1">Biên tập video tương tác</h1><p class="page-subtitle mb-0">{{ form.title }} • Thời lượng {{ formatTime(form.durationSeconds) }}</p></div>
      <div class="d-flex flex-wrap gap-2">
        <button class="btn btn-light" :disabled="previewLoading" @click="openPreview"><span v-if="previewLoading" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-eye"></i> Xem như học viên</button>
        <label class="btn btn-light mb-0" :class="{disabled:uploading}"><i class="bi bi-cloud-arrow-up"></i> {{ uploading ? `Đang tải ${uploadProgress}%` : 'Upload video' }}<input class="visually-hidden" type="file" accept="video/mp4,video/webm,video/ogg,video/quicktime" :disabled="uploading" @change="uploadVideo"></label>
        <button class="btn btn-brand" :disabled="saving || !form.lessonId" @click="saveVideo"><span v-if="saving" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-check-lg"></i> Lưu video</button>
      </div>
    </header>

    <div v-if="message" :class="['alert',messageType==='danger'?'alert-danger':'alert-success']"><i :class="['bi',messageType==='danger'?'bi-exclamation-circle':'bi-check-circle','me-2']"></i>{{ message }}</div>

    <div class="editor-grid">
      <div class="app-card overflow-hidden">
        <div class="video">
          <video v-if="playbackUrl" ref="videoRef" :src="playbackUrl" :poster="form.posterUrl || undefined" controls preload="metadata" @timeupdate="syncTime" @loadedmetadata="syncMetadata"></video>
          <div v-else class="video-empty"><i class="bi bi-cloud-arrow-up"></i><strong>Chưa có video trong project</strong><span>Chọn file MP4, WebM, OGV hoặc MOV để upload.</span></div>
        </div>
        <div class="p-3 d-flex flex-wrap justify-content-between align-items-center gap-3">
          <div><small class="text-secondary">Vị trí hiện tại</small><strong class="d-block fs-4">{{ formatTime(currentTime) }}</strong></div>
          <div v-if="uploadedFile" class="file-meta"><i class="bi bi-file-earmark-play"></i><div><strong>{{ uploadedFile.originalFileName }}</strong><small>{{ formatBytes(uploadedFile.fileSize) }} • {{ uploadedFile.mimeType }}</small></div></div>
          <button class="btn btn-blue" :disabled="!questions.length" @click="addAtCurrent"><i class="bi bi-plus-lg"></i> Thêm câu hỏi tại {{ formatTime(currentTime) }}</button>
        </div>
      </div>
      <aside class="app-card"><div class="p-3"><h2 class="h5 fw-bold mb-1">Câu hỏi tương tác</h2><small class="text-secondary">{{ items.length }} mốc trong video</small></div><div class="interaction" v-for="item in items" :key="item.localKey" :class="{selected:selected?.localKey===item.localKey}" @click="selected=item"><span>{{ formatTime(item.time) }}</span><div><strong>{{ item.label }}</strong><small>{{ item.type }} • {{ item.score || 0 }} điểm</small></div><button class="btn btn-light btn-sm" type="button"><i class="bi bi-grip-vertical"></i></button></div><div v-if="!items.length" class="empty-interactions">Chưa có tương tác cho video này.</div></aside>
    </div>

    <div class="app-card p-4 mt-4"><div class="d-flex justify-content-between mb-2"><h2 class="h5 fw-bold">Dòng thời gian tương tác</h2><small>00:00 — {{ formatTime(form.durationSeconds) }}</small></div><div class="editor-timeline"><div class="track-progress" :style="{width:progressPercent+'%'}"></div><button v-for="item in items" :key="item.localKey" class="timeline-point" :style="{left:markerPercent(item.time)+'%'}" @click="seekTo(item.time);selected=item"><i class="bi bi-patch-question-fill"></i><span>{{ formatTime(item.time) }}</span></button></div></div>

    <div v-if="selected" class="app-card p-4 mt-4">
      <div class="d-flex justify-content-between align-items-center gap-3 mb-3"><h2 class="h5 fw-bold mb-0">Thiết lập tương tác</h2><button class="btn btn-brand" :disabled="interactionSaving || !selected.questionId" @click="saveInteraction"><span v-if="interactionSaving" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-check-lg"></i> Lưu tương tác</button></div>
      <div class="row g-3">
        <div class="col-md-3"><label class="form-label">Thời điểm (giây)</label><input v-model.number="selected.time" type="number" min="0" :max="form.durationSeconds" class="form-control"></div>
        <div class="col-md-6"><label class="form-label">Câu hỏi từ ngân hàng</label><select v-model.number="selected.questionId" class="form-select" @change="syncSelectedQuestion"><option :value="0" disabled>Chọn câu hỏi</option><option v-for="q in questions" :key="q.id" :value="q.id">{{ q.text }}</option></select></div>
        <div class="col-md-3"><label class="form-label">Điểm</label><input v-model.number="selected.score" type="number" min="0" max="10000" class="form-control"></div>
        <div class="col-md-3"><label class="form-label">Số lần làm</label><input v-model.number="selected.attemptLimit" type="number" min="1" max="100" class="form-control"></div>
        <div class="col-md-3"><label class="form-label">Trạng thái</label><select v-model="selected.status" class="form-select"><option value="ACTIVE">Hoạt động</option><option value="INACTIVE">Tạm ẩn</option></select></div>
        <div class="col-md-3 form-check option-check"><input id="required" v-model="selected.required" class="form-check-input" type="checkbox"><label for="required">Bắt buộc trả lời</label></div>
        <div class="col-md-3 form-check option-check"><input id="pause" v-model="selected.pauseVideo" class="form-check-input" type="checkbox"><label for="pause">Tạm dừng video</label></div>
      </div>
    </div>

    <div v-if="previewOpen" class="preview-backdrop" @click.self="previewOpen=false">
      <div class="preview-dialog app-card">
        <div class="preview-header"><div><small>CHẾ ĐỘ XEM HỌC VIÊN • DỮ LIỆU MỚI NHẤT</small><h2>{{ form.title }}</h2></div><button class="btn btn-light btn-sm" @click="previewOpen=false"><i class="bi bi-x-lg"></i></button></div>
        <video v-if="playbackUrl" :src="playbackUrl" :poster="form.posterUrl || undefined" controls preload="metadata"></video>
        <div v-else class="preview-empty">Video chưa có file phát.</div>
        <div class="preview-list"><div v-for="item in items" :key="item.localKey" class="preview-question"><span>{{ formatTime(item.time) }}</span><div><strong>{{ item.label }}</strong><small>{{ item.required ? 'Bắt buộc' : 'Tự chọn' }} • {{ item.score }} điểm</small></div></div><div v-if="!items.length" class="text-secondary">Video chưa có câu hỏi tương tác.</div></div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed,onMounted,reactive,ref } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { formatInteractionTime } from '../../utils/learningRules'

const route=useRoute(),videoRef=ref(null),items=ref([]),questions=ref([]),currentTime=ref(0),selected=ref(null)
const uploading=ref(false),saving=ref(false),interactionSaving=ref(false),previewLoading=ref(false),previewOpen=ref(false),uploadProgress=ref(0),message=ref(''),messageType=ref('success'),uploadedFile=ref(null)
const form=reactive({id:Number(route.params.id),lessonId:0,title:'Video bài giảng',videoUrl:'',posterUrl:'',durationSeconds:600,allowSeek:false,allowSpeed:true,requiredWatchPercent:80,status:'ACTIVE'})
const formatTime=formatInteractionTime
const playbackUrl=computed(()=>resolveApiAssetUrl(form.videoUrl))
const progressPercent=computed(()=>form.durationSeconds?Math.min(100,currentTime.value/form.durationSeconds*100):0)
const pick=(source,...names)=>names.map(name=>source?.[name]).find(value=>value!==undefined&&value!==null)

onMounted(async()=>{await Promise.all([loadVideo(),loadQuestions()]);await loadInteractions()})
async function loadVideo(){try{const data=await axiosClient.get(`/videos/${form.id}`,{params:{_fresh:Date.now()}});form.lessonId=Number(pick(data,'LessonId','lessonId')||0);form.title=pick(data,'Title','title')||form.title;form.videoUrl=pick(data,'VideoUrl','videoUrl')||'';form.posterUrl=pick(data,'PosterUrl','posterUrl')||'';form.durationSeconds=Number(pick(data,'DurationSeconds','durationSeconds')||600);form.allowSeek=Boolean(pick(data,'AllowSeek','allowSeek'));form.allowSpeed=Boolean(pick(data,'AllowSpeed','allowSpeed')??true);form.requiredWatchPercent=Number(pick(data,'RequiredWatchPercent','requiredWatchPercent')||80);form.status=pick(data,'Status','status')||'ACTIVE'}catch(error){showMessage(error.message,'danger')}}
async function loadQuestions(){try{const data=await axiosClient.get('/questions',{params:{pageSize:100,_fresh:Date.now()}});const rows=pick(data,'items','Items')||[];questions.value=rows.map(q=>({id:Number(pick(q,'Id','id')),text:pick(q,'QuestionText','questionText')||'',type:pick(q,'QuestionType','questionType')||'SINGLE_CHOICE'}))}catch(error){showMessage(error.message,'danger')}}
async function loadInteractions(){const data=await axiosClient.get(`/videos/${form.id}/interactions`,{params:{_fresh:Date.now()}});items.value=(Array.isArray(data)?data:[]).map((row,index)=>({id:Number(pick(row,'Id','id')),localKey:`db-${pick(row,'Id','id')}`,questionId:Number(pick(row,'QuestionId','questionId')),time:Number(pick(row,'TimeSeconds','timeSeconds')||0),endTimeSeconds:pick(row,'EndTimeSeconds','endTimeSeconds')??null,label:pick(row,'QuestionText','questionText')||'Câu hỏi',type:pick(row,'QuestionType','questionType')||'SINGLE_CHOICE',interactionType:pick(row,'InteractionType','interactionType')||'QUESTION',required:Boolean(pick(row,'Required','required')),pauseVideo:Boolean(pick(row,'PauseVideo','pauseVideo')),allowSkip:Boolean(pick(row,'AllowSkip','allowSkip')),score:Number(pick(row,'Score','score')||0),attemptLimit:Number(pick(row,'AttemptLimit','attemptLimit')||1),sortOrder:Number(pick(row,'SortOrder','sortOrder')||index+1),status:pick(row,'Status','status')||'ACTIVE'}));items.value.sort((a,b)=>a.time-b.time);selected.value=selected.value?items.value.find(x=>x.id===selected.value.id)||items.value[0]||null:items.value[0]||null}
async function uploadVideo(event){const file=event.target.files?.[0];event.target.value='';if(!file)return;uploading.value=true;uploadProgress.value=0;message.value='';try{const body=new FormData();body.append('file',file);const result=await axiosClient.post('/videos/upload',body,{timeout:0,onUploadProgress:e=>uploadProgress.value=e.total?Math.round(e.loaded/e.total*100):0});form.videoUrl=pick(result,'videoUrl','VideoUrl');uploadedFile.value={originalFileName:pick(result,'originalFileName','OriginalFileName'),fileSize:Number(pick(result,'fileSize','FileSize')),mimeType:pick(result,'mimeType','MimeType')};showMessage('Upload thành công. File đã được lưu trong wwwroot/uploads/videos. Hãy bấm “Lưu video” để ghi URL tương đối vào SQL.')}catch(error){showMessage(error.message,'danger')}finally{uploading.value=false}}
async function saveVideo(){saving.value=true;message.value='';try{await axiosClient.put(`/videos/${form.id}`,{lessonId:form.lessonId,title:form.title,videoUrl:form.videoUrl||null,posterUrl:form.posterUrl||null,durationSeconds:Math.max(1,Math.round(form.durationSeconds)),allowSeek:form.allowSeek,allowSpeed:form.allowSpeed,requiredWatchPercent:form.requiredWatchPercent,status:form.status});showMessage('Đã lưu video. SQL chỉ lưu URL tương đối '+form.videoUrl)}catch(error){showMessage(error.message,'danger')}finally{saving.value=false}}
async function saveInteraction(){if(!selected.value?.questionId)return;interactionSaving.value=true;message.value='';try{const body={questionId:selected.value.questionId,timeSeconds:Math.max(0,Math.round(selected.value.time)),endTimeSeconds:selected.value.endTimeSeconds,interactionType:selected.value.interactionType||'QUESTION',required:selected.value.required,pauseVideo:selected.value.pauseVideo,allowSkip:selected.value.allowSkip,score:Number(selected.value.score)||0,attemptLimit:Math.max(1,Number(selected.value.attemptLimit)||1),sortOrder:selected.value.sortOrder||items.value.indexOf(selected.value)+1,status:selected.value.status||'ACTIVE'};if(selected.value.id)await axiosClient.put(`/video-interactions/${selected.value.id}`,body);else await axiosClient.post(`/videos/${form.id}/interactions`,body);await loadInteractions();showMessage('Đã lưu tương tác vào SQL. Preview sẽ hiển thị nội dung mới nhất.')}catch(error){showMessage(error.message,'danger')}finally{interactionSaving.value=false}}
async function openPreview(){previewLoading.value=true;message.value='';try{await Promise.all([loadVideo(),loadQuestions(),loadInteractions()]);previewOpen.value=true}catch(error){showMessage(error.message,'danger')}finally{previewLoading.value=false}}
function syncSelectedQuestion(){const q=questions.value.find(x=>x.id===selected.value.questionId);if(q){selected.value.label=q.text;selected.value.type=q.type}}
function syncTime(){if(videoRef.value)currentTime.value=videoRef.value.currentTime}
function syncMetadata(){if(videoRef.value?.duration&&Number.isFinite(videoRef.value.duration))form.durationSeconds=Math.round(videoRef.value.duration)}
function seekTo(time){currentTime.value=time;if(videoRef.value)videoRef.value.currentTime=time}
function markerPercent(time){return form.durationSeconds?Math.min(100,time/form.durationSeconds*100):0}
function addAtCurrent(){const q=questions.value[0];if(!q)return;const item={id:0,localKey:`new-${Date.now()}`,questionId:q.id,time:Math.round(currentTime.value),endTimeSeconds:null,label:q.text,type:q.type,interactionType:'QUESTION',score:10,required:true,pauseVideo:true,allowSkip:false,attemptLimit:1,sortOrder:items.value.length+1,status:'ACTIVE'};items.value.push(item);items.value.sort((a,b)=>a.time-b.time);selected.value=item}
function showMessage(text,type='success'){message.value=text;messageType.value=type}
function formatBytes(bytes){if(!bytes)return '0 B';const units=['B','KB','MB','GB'];const index=Math.min(Math.floor(Math.log(bytes)/Math.log(1024)),units.length-1);return `${(bytes/1024**index).toFixed(index?1:0)} ${units[index]}`}
</script>

<style scoped>
.editor-grid{display:grid;grid-template-columns:minmax(0,1fr) 370px;gap:1rem}.video{height:420px;background:#071d2b;position:relative;display:grid;place-items:center;color:white}.video video{width:100%;height:100%;object-fit:contain;background:#000}.video-empty{display:grid;place-items:center;gap:.55rem;color:#d6e1e7;text-align:center}.video-empty i{font-size:3rem;color:#ffff1a}.video-empty span{font-size:.82rem;color:#9fb1bb}.file-meta{display:flex;align-items:center;gap:.7rem;min-width:240px}.file-meta>i{width:40px;height:40px;display:grid;place-items:center;border-radius:8px;background:#e9f6f1;color:#07875a;font-size:1.15rem}.file-meta div{display:grid}.file-meta small{color:#73837d}.interaction{display:grid;grid-template-columns:52px 1fr auto;gap:.65rem;align-items:center;padding:.85rem 1rem;border-top:1px solid #e7ecea;cursor:pointer}.interaction:hover,.interaction.selected{background:#e9f6f1}.interaction>span{color:#005099;font-weight:850}.interaction>div{display:grid}.interaction small{color:#7c8b86;font-size:.72rem}.empty-interactions{padding:2rem 1rem;text-align:center;color:#73837d}.editor-timeline{height:7px;border-radius:5px;background:#e4ebe8;position:relative;margin:3rem 1rem}.track-progress{height:100%;background:#07875a;border-radius:5px}.timeline-point{position:absolute;top:50%;transform:translate(-50%,-50%);border:0;background:transparent;color:#cd1b1b;font-size:1.25rem}.timeline-point span{position:absolute;top:24px;left:50%;transform:translateX(-50%);font-size:.68rem;color:#52645e;white-space:nowrap}.option-check{display:flex;align-items:center;gap:.5rem;padding-top:2.2rem}.option-check .form-check-input{margin:0}.preview-backdrop{position:fixed;inset:0;background:rgba(5,24,35,.68);z-index:1080;display:grid;place-items:center;padding:1.5rem}.preview-dialog{width:min(920px,96vw);max-height:92vh;overflow:auto;padding:1.25rem}.preview-header{display:flex;justify-content:space-between;align-items:flex-start;gap:1rem;margin-bottom:1rem}.preview-header small{color:#07875a;font-weight:800}.preview-header h2{font-size:1.3rem;margin:.2rem 0 0}.preview-dialog>video{display:block;width:100%;max-height:480px;background:#071d2b;border-radius:10px}.preview-empty{min-height:260px;display:grid;place-items:center;background:#edf2f0;color:#73837d;border-radius:10px}.preview-list{display:grid;gap:.65rem;margin-top:1rem}.preview-question{display:flex;gap:1rem;padding:.85rem 1rem;background:#f3f8f6;border-radius:9px}.preview-question>span{color:#005099;font-weight:800}.preview-question>div{display:grid}.preview-question small{color:#73837d}@media(max-width:1000px){.editor-grid{grid-template-columns:1fr}.video{height:48vw;min-height:300px}}@media(max-width:600px){.video{height:250px;min-height:250px}.file-meta{order:3;width:100%}.option-check{padding-top:.5rem}}
</style>
