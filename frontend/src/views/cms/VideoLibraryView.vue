<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title mb-1">Thư viện video</h1>
        <p class="page-subtitle mb-0">Video mặc định chỉ tác giả nhìn thấy; có thể chia sẻ cho giáo viên khác hoặc toàn trường.</p>
      </div>
      <button class="btn btn-brand" @click="openUpload"><i class="bi bi-cloud-arrow-up"></i> Thêm video</button>
    </header>

    <div v-if="message" :class="['alert',messageType==='danger'?'alert-danger':'alert-success']">{{ message }}</div>

    <div class="app-card filter-card mb-3">
      <div class="filter-grid">
        <label class="filter-field search-field">
          <span>Tìm nhanh</span>
          <div class="search-box"><i class="bi bi-search"></i><input v-model.trim="search" class="form-control" placeholder="Tên video, tên file hoặc tác giả..."></div>
        </label>
        <label class="filter-field">
          <span>Quyền truy cập</span>
          <select v-model="accessFilter" class="form-select">
            <option value="ALL">Tất cả được phép xem</option>
            <option value="MINE">Video của tôi</option>
            <option value="SHARED">Được chia sẻ với tôi</option>
            <option value="SCHOOL">Chia sẻ toàn trường</option>
          </select>
        </label>
        <label class="filter-field">
          <span>Định dạng</span>
          <select v-model="sourceFilter" class="form-select"><option value="ALL">Tất cả định dạng</option><option value="MP4">MP4</option><option value="WEBM">WebM</option><option value="OTHER">Định dạng khác</option></select>
        </label>
        <label class="filter-field">
          <span>Tình trạng dùng</span>
          <select v-model="usageFilter" class="form-select"><option value="ALL">Tất cả</option><option value="USED">Đang dùng</option><option value="UNUSED">Chưa sử dụng</option></select>
        </label>
        <label class="filter-field">
          <span>Trạng thái</span>
          <select v-model="statusFilter" class="form-select"><option value="ALL">Tất cả</option><option value="ACTIVE">Hoạt động</option><option value="INACTIVE">Tạm ẩn</option></select>
        </label>
      </div>
      <div class="filter-footer">
        <span><i class="bi bi-collection-play"></i> Tìm thấy <strong>{{ items.length }}</strong> video</span>
        <button v-if="hasFilters" class="btn btn-light btn-sm" @click="clearFilters"><i class="bi bi-arrow-counterclockwise"></i> Xóa bộ lọc</button>
      </div>
    </div>

    <div class="app-card p-2">
      <div class="table-responsive">
        <table class="table align-middle mb-0">
          <thead><tr><th>Video</th><th>Quyền truy cập</th><th>Thời lượng</th><th>Đang sử dụng</th><th>Người tạo</th><th>Ngày tạo</th><th class="text-end">Thao tác</th></tr></thead>
          <tbody>
            <tr v-for="(item,index) in items" :key="item.id">
              <td><div class="video-name"><span class="video-thumb" :style="{backgroundImage:`url(${thumbnailFor(item,index)})`}"><i class="bi bi-play-fill"></i></span><div><strong>{{ item.title }}</strong><small>{{ item.originalFileName || item.videoUrl || 'Chưa có file' }}</small></div></div></td>
              <td><span :class="['access-badge',`access-${item.accessType.toLowerCase()}`]"><i :class="['bi',accessIcon(item.accessType)]"></i>{{ accessLabel(item) }}</span></td>
              <td>{{ formatTime(item.durationSeconds) }}</td>
              <td><span class="badge badge-soft-primary">{{ item.usageCount }} bài học</span></td>
              <td><strong class="author-name">{{ item.createdByName }}</strong><small v-if="item.isOwner" class="d-block text-secondary">Tác giả: bạn</small></td>
              <td>{{ formatDate(item.createdAt) }}</td>
              <td class="text-end action-cell">
                <button v-if="item.canEdit" class="btn btn-light btn-sm edit-button" title="Sửa thông tin video" @click="openEdit(item)"><i class="bi bi-pencil-square"></i></button>
                <RouterLink v-if="item.firstVideoId" class="btn btn-light btn-sm" :to="`/cms/videos/${item.firstVideoId}/editor`" title="Mở một bản đang dùng"><i class="bi bi-sliders"></i></RouterLink>
                <button v-if="item.canShare" class="btn btn-light btn-sm share-button" title="Quản lý chia sẻ" @click="openShare(item)"><i class="bi bi-share"></i></button>
                <button v-if="item.isOwner||item.canDelete" class="btn btn-light btn-sm text-danger" :disabled="!item.canDelete" :title="item.canDelete?'Xóa video':'Video đang được sử dụng nên chưa thể xóa'" @click="remove(item)"><i class="bi bi-trash"></i></button>
              </td>
            </tr>
            <tr v-if="!loading&&!items.length"><td colspan="7" class="text-center text-secondary py-5"><i class="bi bi-search d-block fs-2 mb-2"></i>Không có video phù hợp với bộ lọc.</td></tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-brand"></span></div>
    </div>

    <div v-if="uploadModal" class="modal-mask" @click.self="uploadModal=false">
      <form class="app-card upload-modal" @submit.prevent="save">
        <div class="modal-heading"><div><small>{{ form.id ? 'QUẢN LÝ TÀI NGUYÊN VIDEO' : 'VIDEO CỦA TÔI' }}</small><h2>{{ form.id ? 'Sửa thông tin video' : 'Thêm video vào thư viện' }}</h2><p>{{ form.id ? 'Quản trị viên được sửa mọi video; tác giả chỉ sửa video của mình. Thay đổi sẽ đồng bộ tới các bài học đang dùng.' : 'Video mới được đặt ở chế độ riêng tư. Bạn có thể chia sẻ sau khi lưu.' }}</p></div><button type="button" class="btn-close" @click="uploadModal=false"></button></div>
        <label v-if="!form.videoUrl" class="drop-zone" :class="{disabled:uploading}"><i class="bi bi-cloud-arrow-up"></i><strong>{{ uploading?`Đang tải lên ${uploadProgress}%`:'Chọn file video' }}</strong><span>MP4, WebM, OGV hoặc MOV; file lưu trong project.</span><input class="visually-hidden" type="file" accept="video/mp4,video/webm,video/ogg,video/quicktime" :disabled="uploading" @change="upload"></label>
        <div v-else class="video-preview"><video ref="metadataVideo" :src="playbackUrl" controls preload="metadata" @loadedmetadata="readDuration"></video><label class="btn btn-light btn-sm mt-2" :class="{disabled:uploading}"><i class="bi bi-arrow-repeat"></i> {{ uploading?`Đang tải ${uploadProgress}%`:'Thay file video' }}<input class="visually-hidden" type="file" accept="video/mp4,video/webm,video/ogg,video/quicktime" :disabled="uploading" @change="upload"></label></div>
        <div class="row g-3 mt-1"><div class="col-md-6"><label class="form-label">Tên video</label><input v-model.trim="form.title" class="form-control" required maxlength="500"></div><div class="col-md-3"><label class="form-label">Thời lượng (giây)</label><input v-model.number="form.durationSeconds" class="form-control" type="number" min="1" required></div><div class="col-md-3"><label class="form-label">Trạng thái</label><select v-model="form.status" class="form-select"><option value="ACTIVE">Hoạt động</option><option value="INACTIVE">Tạm ẩn</option></select></div><div class="col-12"><label class="form-label">URL tương đối trong project</label><input v-model="form.videoUrl" class="form-control" readonly required></div></div>
        <div class="modal-actions"><button type="button" class="btn btn-light" @click="uploadModal=false">Hủy</button><button class="btn btn-brand" :disabled="saving||uploading||!form.videoUrl"><span v-if="saving" class="spinner-border spinner-border-sm me-1"></span>{{ form.id ? 'Lưu thay đổi' : 'Lưu vào thư viện' }}</button></div>
      </form>
    </div>

    <div v-if="shareModal" class="modal-mask" @click.self="closeShare">
      <form class="app-card upload-modal share-modal" @submit.prevent="saveSharing">
        <div class="modal-heading"><div><small>QUYỀN TRUY CẬP VIDEO</small><h2>Chia sẻ “{{ shareForm.title }}”</h2><p>Chỉ cấp quyền nhìn thấy và sử dụng trong bài học; người nhận không thể xóa hoặc chia sẻ lại.</p></div><button type="button" class="btn-close" @click="closeShare"></button></div>
        <div v-if="sharingLoading" class="text-center p-5"><span class="spinner-border text-brand"></span></div>
        <template v-else>
          <div class="scope-options">
            <label :class="['scope-option',{selected:shareForm.shareScope==='PRIVATE'}]"><input v-model="shareForm.shareScope" type="radio" value="PRIVATE"><i class="bi bi-lock"></i><span><strong>Chỉ mình tôi</strong><small>Chỉ tác giả và quản trị viên nhìn thấy.</small></span></label>
            <label :class="['scope-option',{selected:shareForm.shareScope==='SELECTED'}]"><input v-model="shareForm.shareScope" type="radio" value="SELECTED"><i class="bi bi-person-check"></i><span><strong>Giáo viên được chọn</strong><small>Chia sẻ cho một hoặc nhiều giáo viên cụ thể.</small></span></label>
            <label :class="['scope-option',{selected:shareForm.shareScope==='SCHOOL'}]"><input v-model="shareForm.shareScope" type="radio" value="SCHOOL"><i class="bi bi-building"></i><span><strong>Toàn trường</strong><small>Mọi tài khoản giáo viên đều có thể sử dụng.</small></span></label>
          </div>
          <div v-if="shareForm.shareScope==='SELECTED'" class="teacher-picker">
            <div class="teacher-picker-head"><label><i class="bi bi-search"></i><input v-model.trim="teacherSearch" class="form-control" placeholder="Tìm tên, mã hoặc email giáo viên..."></label><span>Đã chọn <strong>{{ shareForm.teacherIds.length }}</strong></span></div>
            <div class="teacher-list">
              <label v-for="teacher in filteredTeachers" :key="teacher.id" class="teacher-option"><input v-model="shareForm.teacherIds" type="checkbox" :value="teacher.id"><span class="teacher-avatar">{{ initials(teacher.fullName) }}</span><span><strong>{{ teacher.fullName }}</strong><small>{{ teacher.teacherCode }} · {{ teacher.email }}</small></span></label>
              <p v-if="!filteredTeachers.length" class="text-center text-secondary m-0 py-4">Không có giáo viên phù hợp.</p>
            </div>
          </div>
        </template>
        <div class="modal-actions"><button type="button" class="btn btn-light" @click="closeShare">Hủy</button><button class="btn btn-brand" :disabled="sharingLoading||sharingSaving||(shareForm.shareScope==='SELECTED'&&!shareForm.teacherIds.length)"><span v-if="sharingSaving" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-share me-1"></i>Lưu chia sẻ</button></div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed,onMounted,reactive,ref,watch } from 'vue'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { formatInteractionTime } from '../../utils/learningRules'

const items=ref([]),search=ref(''),accessFilter=ref('ALL'),sourceFilter=ref('ALL'),usageFilter=ref('ALL'),statusFilter=ref('ALL'),loading=ref(true)
const uploadModal=ref(false),uploading=ref(false),saving=ref(false),uploadProgress=ref(0),metadataVideo=ref(null)
const shareModal=ref(false),sharingLoading=ref(false),sharingSaving=ref(false),shareTeachers=ref([]),teacherSearch=ref('')
const message=ref(''),messageType=ref('success'),form=reactive(blank()),shareForm=reactive({assetId:0,title:'',shareScope:'PRIVATE',teacherIds:[]})
const playbackUrl=computed(()=>resolveApiAssetUrl(form.videoUrl)),pick=(source,...names)=>names.map(name=>source?.[name]).find(value=>value!==undefined&&value!==null),formatTime=formatInteractionTime
const hasFilters=computed(()=>Boolean(search.value)||[accessFilter.value,sourceFilter.value,usageFilter.value,statusFilter.value].some(value=>value!=='ALL'))
const filteredTeachers=computed(()=>{const term=teacherSearch.value.toLocaleLowerCase('vi');return shareTeachers.value.filter(t=>!term||`${t.fullName} ${t.email} ${t.teacherCode}`.toLocaleLowerCase('vi').includes(term))})
const fallbackThumbnails=[
  new URL('../../assets/eduvers/images/courses/course-list-img-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-list-img-2.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-list-img-3.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-list-img-4.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-list-img-5.jpg',import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-1-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-1-2.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-1-3.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-1-4.jpg',import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-2-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-2-2.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-2-3.jpg',import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-3-2.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-3-3.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-3-4.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-3-5.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/courses-3-6.jpg',import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-details-img-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-details-client-img-1.jpg',import.meta.url).href,new URL('../../assets/eduvers/images/courses/course-details-Instructor-img.jpg',import.meta.url).href
]

let timer
watch([search,accessFilter,sourceFilter,usageFilter,statusFilter],()=>{clearTimeout(timer);timer=setTimeout(load,250)})
onMounted(load)
function blank(){return{id:0,title:'',videoUrl:'',posterUrl:'',durationSeconds:60,originalFileName:'',fileSize:0,mimeType:'',status:'ACTIVE'}}
async function load(){loading.value=true;try{const rows=await axiosClient.get('/video-library',{params:{search:search.value||undefined,access:accessFilter.value,source:sourceFilter.value,usage:usageFilter.value,status:statusFilter.value,_fresh:Date.now()}});items.value=(Array.isArray(rows)?rows:[]).map(row=>({id:Number(pick(row,'Id','id')),title:pick(row,'Title','title'),videoUrl:pick(row,'VideoUrl','videoUrl')||'',posterUrl:pick(row,'PosterUrl','posterUrl')||'',originalFileName:pick(row,'OriginalFileName','originalFileName')||'',fileSize:Number(pick(row,'FileSize','fileSize')||0),mimeType:pick(row,'MimeType','mimeType')||'',durationSeconds:Number(pick(row,'DurationSeconds','durationSeconds')||0),status:pick(row,'Status','status')||'ACTIVE',usageCount:Number(pick(row,'UsageCount','usageCount')||0),createdByName:pick(row,'CreatedByName','createdByName')||'',createdAt:pick(row,'CreatedAt','createdAt'),firstVideoId:Number(pick(row,'FirstVideoId','firstVideoId')||0),shareScope:pick(row,'ShareScope','shareScope')||'PRIVATE',accessType:pick(row,'AccessType','accessType')||'OWNER',sharedTeacherCount:Number(pick(row,'SharedTeacherCount','sharedTeacherCount')||0),isOwner:Boolean(pick(row,'IsOwner','isOwner')),canEdit:Boolean(pick(row,'CanEdit','canEdit')),canShare:Boolean(pick(row,'CanShare','canShare')),canDelete:Boolean(pick(row,'CanDelete','canDelete'))}))}catch(error){show(error.message,'danger')}finally{loading.value=false}}
function clearFilters(){search.value='';accessFilter.value=sourceFilter.value=usageFilter.value=statusFilter.value='ALL'}
function thumbnailFor(item,index){const projectPoster=item.posterUrl&&(!/^https?:\/\//i.test(item.posterUrl)||/^https?:\/\/localhost(?::\d+)?\//i.test(item.posterUrl));return projectPoster?resolveApiAssetUrl(item.posterUrl):fallbackThumbnails[index%fallbackThumbnails.length]}
function accessIcon(type){return type==='OWNER'?'bi-lock':type==='SCHOOL'?'bi-building':type==='SHARED'?'bi-person-check':'bi-shield-check'}
function accessLabel(item){if(item.accessType==='OWNER'){if(item.shareScope==='SCHOOL')return'Tôi · Toàn trường';if(item.shareScope==='SELECTED')return`Tôi · ${item.sharedTeacherCount} giáo viên`;return'Chỉ mình tôi'}if(item.accessType==='SCHOOL')return'Toàn trường';if(item.accessType==='SHARED')return'Chia sẻ cho tôi';return'Quản trị viên'}
function openUpload(){Object.assign(form,blank());uploadProgress.value=0;uploadModal.value=true}
function openEdit(item){Object.assign(form,blank(),{id:item.id,title:item.title,videoUrl:item.videoUrl,posterUrl:item.posterUrl,durationSeconds:item.durationSeconds,originalFileName:item.originalFileName,fileSize:item.fileSize,mimeType:item.mimeType,status:item.status});uploadProgress.value=0;uploadModal.value=true}
async function upload(event){const file=event.target.files?.[0];event.target.value='';if(!file)return;uploading.value=true;try{const body=new FormData();body.append('file',file);const result=await axiosClient.post('/videos/upload',body,{timeout:0,onUploadProgress:e=>uploadProgress.value=e.total?Math.round(e.loaded/e.total*100):0});form.videoUrl=pick(result,'videoUrl','VideoUrl');form.originalFileName=pick(result,'originalFileName','OriginalFileName')||file.name;form.fileSize=Number(pick(result,'fileSize','FileSize')||file.size);form.mimeType=pick(result,'mimeType','MimeType')||file.type;form.title=file.name.replace(/\.[^.]+$/,'')}catch(error){show(error.message,'danger')}finally{uploading.value=false}}
function readDuration(){if(metadataVideo.value?.duration&&Number.isFinite(metadataVideo.value.duration))form.durationSeconds=Math.max(1,Math.round(metadataVideo.value.duration))}
async function save(){saving.value=true;try{const payload={...form,durationSeconds:Math.max(1,Math.round(form.durationSeconds))};if(form.id)await axiosClient.put(`/video-library/${form.id}`,payload);else await axiosClient.post('/video-library',payload);const edited=Boolean(form.id);uploadModal.value=false;await load();show(edited?'Đã cập nhật video và đồng bộ tới các bài học đang sử dụng.':'Đã thêm video riêng tư vào thư viện. Chỉ bạn nhìn thấy cho đến khi chia sẻ.')}catch(error){show(error.message,'danger')}finally{saving.value=false}}
async function openShare(item){shareModal.value=true;sharingLoading.value=true;teacherSearch.value='';Object.assign(shareForm,{assetId:item.id,title:item.title,shareScope:item.shareScope,teacherIds:[]});try{const data=await axiosClient.get(`/video-library/${item.id}/sharing`,{params:{_fresh:Date.now()}}),asset=pick(data,'Asset','asset')||{};shareForm.shareScope=pick(asset,'ShareScope','shareScope')||'PRIVATE';shareTeachers.value=(pick(data,'Teachers','teachers')||[]).map(row=>({id:Number(pick(row,'Id','id')),fullName:pick(row,'FullName','fullName')||'',email:pick(row,'Email','email')||'',teacherCode:pick(row,'TeacherCode','teacherCode')||'',isSelected:Boolean(pick(row,'IsSelected','isSelected'))}));shareForm.teacherIds=shareTeachers.value.filter(t=>t.isSelected).map(t=>t.id)}catch(error){closeShare();show(error.message,'danger')}finally{sharingLoading.value=false}}
function closeShare(){shareModal.value=false;teacherSearch.value=''}
async function saveSharing(){sharingSaving.value=true;try{await axiosClient.put(`/video-library/${shareForm.assetId}/sharing`,{shareScope:shareForm.shareScope,teacherIds:shareForm.shareScope==='SELECTED'?shareForm.teacherIds:[]});closeShare();await load();show(shareForm.shareScope==='PRIVATE'?'Đã chuyển video về chế độ chỉ mình tôi.':shareForm.shareScope==='SCHOOL'?'Đã chia sẻ video cho toàn bộ giáo viên trong trường.':`Đã chia sẻ video cho ${shareForm.teacherIds.length} giáo viên.`)}catch(error){show(error.message,'danger')}finally{sharingSaving.value=false}}
async function remove(item){if(!item.canDelete)return;if(!window.confirm(`Xóa “${item.title}” khỏi thư viện?`))return;try{await axiosClient.delete(`/video-library/${item.id}`);await load();show('Đã xóa video chưa sử dụng khỏi thư viện.')}catch(error){show(error.message,'danger')}}
function initials(name){return String(name||'GV').split(/\s+/).filter(Boolean).slice(-2).map(x=>x[0]).join('').toUpperCase()}
function formatDate(value){return value?new Intl.DateTimeFormat('vi-VN').format(new Date(value)):'—'}
function show(text,type='success'){message.value=text;messageType.value=type}
</script>

<style scoped>
/* Bộ lọc thư viện và hộp thoại phân quyền video. */
.filter-card{padding:1rem}.filter-grid{display:grid;grid-template-columns:minmax(280px,2fr) repeat(4,minmax(145px,1fr));gap:.8rem}.filter-field{display:grid;gap:.38rem}.filter-field>span{font-size:.76rem;font-weight:700;color:#5f6f69}.search-box{position:relative}.search-box i{position:absolute;left:.85rem;top:50%;transform:translateY(-50%);color:#75857f}.search-box input{padding-left:2.35rem}.filter-footer{display:flex;justify-content:space-between;align-items:center;gap:1rem;margin-top:.85rem;padding-top:.8rem;border-top:1px solid #eee8e5;color:#75857f;font-size:.82rem}.filter-footer i{color:var(--eduvers-base);margin-right:.3rem}.video-name{display:flex;align-items:center;gap:.75rem;min-width:310px}.video-thumb{position:relative;width:68px;height:46px;flex:0 0 68px;overflow:hidden;border-radius:8px;background-position:center;background-size:cover;display:grid;place-items:center}.video-thumb::after{content:'';position:absolute;inset:0;background:linear-gradient(135deg,rgba(5,24,35,.06),rgba(5,24,35,.34))}.video-thumb i{position:relative;z-index:1;width:24px;height:24px;display:grid;place-items:center;border-radius:50%;color:#fff;background:rgba(211,34,77,.9);font-size:.75rem}.video-name>div{display:grid}.video-name small{color:#75857f;max-width:340px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.author-name{font-size:.86rem}.access-badge{display:inline-flex;align-items:center;gap:.35rem;padding:.38rem .58rem;border-radius:7px;font-size:.75rem;font-weight:700;white-space:nowrap;background:#f1efed;color:#5d6965}.access-owner{background:#fbe6ec;color:#b41640}.access-school{background:#e6f0f8;color:#005099}.access-shared{background:#e6f5ef;color:#087853}.access-admin{background:#f1efed;color:#5d6965}.action-cell{white-space:nowrap}.action-cell .btn+.btn{margin-left:.3rem}.share-button{color:#005099}.modal-mask{position:fixed;inset:0;background:rgba(5,24,35,.65);z-index:2000;display:grid;place-items:center;padding:1rem}.upload-modal{width:min(760px,96vw);max-height:94vh;overflow:auto;padding:1.5rem}.share-modal{width:min(820px,96vw)}.modal-heading{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1.2rem;gap:1rem}.modal-heading small{color:var(--eduvers-base);font-weight:800;letter-spacing:.08em}.modal-heading h2{font-size:1.35rem;margin:.2rem 0}.modal-heading p{color:#75857f;margin:.35rem 0 0;font-size:.86rem}.drop-zone{min-height:220px;border:1px dashed #a7b7b1;border-radius:12px;display:grid;place-items:center;align-content:center;gap:.5rem;background:#f8faf9;cursor:pointer}.drop-zone i{font-size:2.7rem;color:var(--eduvers-base)}.drop-zone span{color:#75857f}.upload-modal video{display:block;width:100%;max-height:330px;background:#071922;border-radius:10px}.modal-actions{display:flex;justify-content:flex-end;gap:.6rem;margin-top:1.5rem}.scope-options{display:grid;grid-template-columns:repeat(3,1fr);gap:.75rem}.scope-option{position:relative;display:flex;gap:.7rem;padding:1rem;border:1px solid #e6e1de;border-radius:10px;cursor:pointer;background:#fff}.scope-option.selected{background:rgba(var(--eduvers-base-rgb),.06);border-color:var(--eduvers-base)}.scope-option input{position:absolute;opacity:0}.scope-option>i{width:34px;height:34px;border-radius:8px;display:grid;place-items:center;background:var(--eduvers-primary);color:var(--eduvers-base);flex:0 0 34px}.scope-option span{display:grid;gap:.25rem}.scope-option strong{font-size:.88rem}.scope-option small{font-size:.75rem;line-height:1.4;color:#75857f}.teacher-picker{margin-top:1rem;padding:1rem;background:var(--eduvers-primary);border-radius:10px}.teacher-picker-head{display:flex;align-items:center;justify-content:space-between;gap:1rem;margin-bottom:.75rem}.teacher-picker-head>label{position:relative;flex:1}.teacher-picker-head i{position:absolute;left:.8rem;top:50%;transform:translateY(-50%);color:#75857f}.teacher-picker-head input{padding-left:2.2rem}.teacher-picker-head>span{font-size:.78rem;color:#75857f;white-space:nowrap}.teacher-list{max-height:280px;overflow:auto;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.55rem;padding-right:.25rem}.teacher-option{display:flex;align-items:center;gap:.65rem;padding:.7rem;background:#fff;border-radius:9px;cursor:pointer}.teacher-option>input{accent-color:var(--eduvers-base)}.teacher-avatar{width:34px;height:34px;display:grid;place-items:center;border-radius:50%;background:#e6f0f8;color:#005099;font-size:.72rem;font-weight:800;flex:0 0 34px}.teacher-option>span:last-child{display:grid;min-width:0}.teacher-option strong{font-size:.82rem}.teacher-option small{font-size:.72rem;color:#75857f;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.text-brand{color:var(--eduvers-base)!important}@media(max-width:1200px){.filter-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.search-field{grid-column:1/-1}}@media(max-width:700px){.filter-grid,.scope-options,.teacher-list{grid-template-columns:1fr}.filter-footer,.teacher-picker-head{align-items:flex-start;flex-direction:column}.teacher-picker-head>label{width:100%}}
</style>
