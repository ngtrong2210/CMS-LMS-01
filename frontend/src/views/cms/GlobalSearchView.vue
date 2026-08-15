<template>
  <section>
    <header class="search-page-header mb-4">
      <div>
        <span class="search-kicker"><i class="bi bi-stars"></i> TÌM KIẾM TOÀN HỆ THỐNG</span>
        <h1 class="page-title mb-1">Tìm nhanh dữ liệu quản trị</h1>
        <p class="page-subtitle mb-0">Tra cứu khóa học, bài học, video, câu hỏi và học viên từ một nơi.</p>
      </div>
      <form class="page-search" @submit.prevent="submitSearch">
        <i class="bi bi-search"></i>
        <input v-model="query" type="search" aria-label="Từ khóa tìm kiếm toàn hệ thống" placeholder="Nhập ít nhất 2 ký tự..." autocomplete="off">
        <button class="btn btn-brand" :disabled="loading"><span v-if="loading" class="spinner-border spinner-border-sm"></span><span v-else>Tìm kiếm</span></button>
      </form>
      <div v-if="validationMessage" class="search-validation"><i class="bi bi-info-circle"></i>{{ validationMessage }}</div>
    </header>

    <div v-if="error" class="alert alert-danger"><i class="bi bi-exclamation-triangle me-2"></i>{{ error }}</div>

    <template v-if="searchedTerm">
      <div class="search-summary app-card mb-3">
        <div><span>KẾT QUẢ CHO</span><strong>“{{ searchedTerm }}”</strong></div>
        <span class="result-total">{{ items.length }} kết quả</span>
      </div>

      <div class="type-tabs mb-3" role="tablist" aria-label="Lọc loại kết quả">
        <button v-for="type in types" :key="type.value" type="button" :class="['type-tab',{active:activeType===type.value}]" @click="activeType=type.value">
          <i :class="['bi',type.icon]"></i>{{ type.label }} <span>{{ countByType(type.value) }}</span>
        </button>
      </div>

      <div v-if="loading" class="app-card search-state"><span class="spinner-border text-brand"></span><p>Đang tìm trong dữ liệu SQL...</p></div>
      <div v-else-if="filteredItems.length" class="result-list">
        <RouterLink v-for="item in filteredItems" :key="`${item.type}-${item.id}`" :to="item.targetUrl" class="result-card app-card">
          <span :class="['result-icon',`type-${item.type.toLowerCase()}`]"><i :class="['bi',item.icon]"></i></span>
          <span class="result-copy">
            <span class="result-heading"><span class="result-type">{{ typeLabel(item.type) }}</span><span :class="['status-dot',statusClass(item.status)]">{{ statusLabel(item.status) }}</span></span>
            <strong>{{ item.title }}</strong>
            <small>{{ item.subtitle }}</small>
            <span v-if="item.description" class="result-description">{{ item.description }}</span>
          </span>
          <span class="result-open"><span>Mở</span><i class="bi bi-arrow-right"></i></span>
        </RouterLink>
      </div>
      <div v-else class="app-card search-state">
        <span class="empty-icon"><i class="bi bi-search"></i></span>
        <h2>Chưa tìm thấy dữ liệu phù hợp</h2>
        <p>Thử tìm bằng mã khóa học, tên bài học, nội dung câu hỏi, tên video hoặc mã học viên.</p>
      </div>
    </template>

    <div v-else class="search-guide">
      <article v-for="guide in guides" :key="guide.title" class="app-card guide-card">
        <span><i :class="['bi',guide.icon]"></i></span><div><strong>{{ guide.title }}</strong><p>{{ guide.description }}</p><small>Ví dụ: {{ guide.example }}</small></div>
      </article>
    </div>
  </section>
</template>

<script setup>
import { computed,ref,watch } from 'vue'
import { useRoute,useRouter } from 'vue-router'
import axiosClient from '../../api/axiosClient'

const route=useRoute(),router=useRouter()
const query=ref(''),searchedTerm=ref(''),items=ref([]),loading=ref(false),error=ref(''),validationMessage=ref(''),activeType=ref('')
const pick=(source,...names)=>names.map(name=>source?.[name]).find(value=>value!==undefined&&value!==null)
const types=[
  {value:'',label:'Tất cả',icon:'bi-grid'},
  {value:'COURSE',label:'Khóa học',icon:'bi-journal-bookmark'},
  {value:'LESSON',label:'Bài học',icon:'bi-play-btn'},
  {value:'VIDEO',label:'Video',icon:'bi-collection-play'},
  {value:'QUESTION',label:'Câu hỏi',icon:'bi-patch-question'},
  {value:'STUDENT',label:'Học viên',icon:'bi-people'}
]
const guides=[
  {title:'Khóa học và bài học',icon:'bi-journal-bookmark',description:'Tìm theo mã, tiêu đề, chương, mô tả hoặc tên giảng viên.',example:'VUE-001, Composition API'},
  {title:'Video dùng chung',icon:'bi-collection-play',description:'Tìm theo tên hiển thị, tên tệp hoặc đường dẫn video trong thư viện.',example:'Bài mở đầu, z3.mp4'},
  {title:'Ngân hàng câu hỏi',icon:'bi-patch-question',description:'Tìm trực tiếp trong nội dung, giải thích, loại và độ khó câu hỏi.',example:'Vue Router, SINGLE_CHOICE'},
  {title:'Học viên',icon:'bi-people',description:'Tìm theo họ tên, mã học viên, tài khoản hoặc địa chỉ email.',example:'HV001, Nguyễn Văn Học'}
]
const filteredItems=computed(()=>activeType.value?items.value.filter(item=>item.type===activeType.value):items.value)
let requestId=0

watch(()=>route.query.q,async value=>{
  const term=String(value||'').trim()
  query.value=term
  activeType.value=''
  validationMessage.value=''
  if(term.length<2){searchedTerm.value='';items.value=[];error.value='';return}
  await runSearch(term)
},{immediate:true})

async function runSearch(term){
  const current=++requestId;loading.value=true;error.value='';searchedTerm.value=term
  try{
    const rows=await axiosClient.get('/cms/search',{params:{q:term,limit:100,_fresh:Date.now()}})
    if(current!==requestId)return
    items.value=(Array.isArray(rows)?rows:[]).map(row=>({
      type:pick(row,'ResultType','resultType')||'',id:Number(pick(row,'EntityId','entityId')),parentId:Number(pick(row,'ParentId','parentId')||0),
      title:pick(row,'Title','title')||'',subtitle:pick(row,'Subtitle','subtitle')||'',description:pick(row,'Description','description')||'',
      status:pick(row,'Status','status')||'',targetUrl:pick(row,'TargetUrl','targetUrl')||'/cms/dashboard',icon:pick(row,'Icon','icon')||'bi-search'
    }))
  }catch(e){if(current===requestId){items.value=[];error.value=e.message}}finally{if(current===requestId)loading.value=false}
}
function submitSearch(){
  const term=query.value.trim()
  if(term.length<2){validationMessage.value='Vui lòng nhập ít nhất 2 ký tự để tìm kiếm.';return}
  validationMessage.value=''
  if(term===String(route.query.q||'').trim())runSearch(term)
  else router.push({path:'/cms/search',query:{q:term}})
}
function countByType(type){return type?items.value.filter(item=>item.type===type).length:items.value.length}
function typeLabel(type){return types.find(item=>item.value===type)?.label||type}
function statusLabel(status){return{ACTIVE:'Hoạt động',INACTIVE:'Tạm ẩn',PUBLISHED:'Đã xuất bản',DRAFT:'Bản nháp',ARCHIVED:'Lưu trữ',LOCKED:'Đã khóa'}[status]||status||'Sẵn sàng'}
function statusClass(status){return['ACTIVE','PUBLISHED'].includes(status)?'active':['INACTIVE','LOCKED','ARCHIVED'].includes(status)?'inactive':'draft'}
</script>

<style scoped>
.search-page-header{padding:1.4rem;border-radius:12px;background:var(--eduvers-white);box-shadow:0 8px 28px rgba(13,41,68,.045)}.search-kicker{display:flex;align-items:center;gap:.4rem;margin-bottom:.35rem;color:var(--eduvers-base);font-size:.65rem;font-weight:800;letter-spacing:.09em}.page-search{display:grid;grid-template-columns:22px minmax(0,1fr) auto;align-items:center;gap:.55rem;margin-top:1.2rem;padding:.4rem .4rem .4rem .9rem;border-radius:10px;background:var(--eduvers-primary)}.page-search>i{color:#71817b}.page-search input{height:42px;border:0;outline:0;background:transparent;color:var(--eduvers-black)}.page-search .btn{min-width:112px}.search-validation{display:flex;align-items:center;gap:.4rem;margin-top:.65rem;color:var(--eduvers-base);font-size:.78rem}.search-summary{display:flex;align-items:center;justify-content:space-between;gap:1rem;padding:1rem 1.2rem}.search-summary>div{display:grid}.search-summary span{color:#7b8984;font-size:.67rem;font-weight:750;letter-spacing:.06em}.search-summary strong{font-size:1rem}.result-total{padding:.4rem .7rem;border-radius:999px;background:rgba(var(--eduvers-base-rgb),.1);color:var(--eduvers-base)!important;letter-spacing:0!important}.type-tabs{display:flex;gap:.55rem;overflow-x:auto;padding-bottom:.2rem}.type-tab{display:flex;align-items:center;gap:.42rem;white-space:nowrap;padding:.62rem .82rem;border:0;border-radius:9px;background:var(--eduvers-white);color:#60716b;font-size:.78rem;font-weight:700}.type-tab>span{display:grid;place-items:center;min-width:21px;height:21px;padding:0 .35rem;border-radius:999px;background:var(--eduvers-primary);font-size:.65rem}.type-tab:hover,.type-tab.active{background:var(--eduvers-base);color:#fff}.type-tab.active>span,.type-tab:hover>span{background:rgba(255,255,255,.18)}.result-list{display:grid;gap:.7rem}.result-card{display:grid;grid-template-columns:50px minmax(0,1fr) auto;align-items:center;gap:1rem;padding:1rem 1.1rem;color:var(--eduvers-black);transition:transform .16s ease,box-shadow .16s ease}.result-card:hover{color:var(--eduvers-black);transform:translateY(-2px);box-shadow:0 12px 30px rgba(13,41,68,.08)}.result-icon{width:50px;height:50px;display:grid;place-items:center;border-radius:10px;color:var(--eduvers-base);background:rgba(var(--eduvers-base-rgb),.1);font-size:1.15rem}.type-video{color:#005099;background:rgba(0,80,153,.1)}.type-student{color:#ff5543;background:rgba(255,85,67,.1)}.result-copy{display:grid;min-width:0}.result-copy>strong{margin:.18rem 0;font-size:.95rem;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.result-copy>small{color:#6f7e79}.result-heading{display:flex;align-items:center;gap:.55rem}.result-type{color:var(--eduvers-base);font-size:.63rem;font-weight:800;letter-spacing:.07em}.status-dot{font-size:.62rem}.status-dot::before{content:'';display:inline-block;width:6px;height:6px;margin-right:.3rem;border-radius:50%;background:#d1a100}.status-dot.active::before{background:#07875a}.status-dot.inactive::before{background:#8a9691}.result-description{margin-top:.35rem;color:#7b8984;font-size:.73rem;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.result-open{display:flex;align-items:center;gap:.45rem;color:var(--eduvers-base);font-size:.75rem;font-weight:750}.search-state{display:grid;justify-items:center;padding:3.5rem 1.5rem;text-align:center}.search-state p{margin:.55rem 0 0;color:#73827d}.search-state h2{margin:.9rem 0 0;font-size:1.15rem}.empty-icon{width:58px;height:58px;display:grid;place-items:center;border-radius:50%;color:var(--eduvers-base);background:rgba(var(--eduvers-base-rgb),.1);font-size:1.35rem}.search-guide{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem}.guide-card{display:flex;gap:1rem;padding:1.2rem}.guide-card>span{width:45px;height:45px;display:grid;place-items:center;flex:0 0 auto;border-radius:9px;color:var(--eduvers-base);background:rgba(var(--eduvers-base-rgb),.1)}.guide-card>div{display:grid}.guide-card p{margin:.3rem 0;color:#72817c;font-size:.8rem}.guide-card small{color:#9a6c78;font-size:.7rem}@media(max-width:700px){.search-page-header{padding:1rem}.page-search{grid-template-columns:20px minmax(0,1fr)}.page-search .btn{grid-column:1/-1;width:100%}.search-guide{grid-template-columns:1fr}.result-card{grid-template-columns:42px minmax(0,1fr);gap:.7rem}.result-icon{width:42px;height:42px}.result-open{display:none}.result-description{white-space:normal;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}}
</style>
