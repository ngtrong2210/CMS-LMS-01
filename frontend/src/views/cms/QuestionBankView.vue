<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4"><div><h1 class="page-title mb-1">Ngân hàng câu hỏi</h1><p class="page-subtitle mb-0">Quản lý câu hỏi dùng trong video và bài kiểm tra.</p></div><button class="btn btn-brand" @click="createQuestion"><i class="bi bi-plus-lg"></i> Thêm câu hỏi</button></header>
    <div v-if="message" :class="['alert',messageType==='danger'?'alert-danger':'alert-success']">{{ message }}</div>
    <div class="app-card p-3 mb-3"><form class="row g-2" @submit.prevent="loadQuestions"><div class="col-md-7"><input v-model="search" class="form-control" placeholder="Tìm nội dung câu hỏi..."></div><div class="col-md-3"><select v-model="type" class="form-select"><option value="">Tất cả loại</option><option>SINGLE_CHOICE</option><option>MULTIPLE_CHOICE</option><option>TRUE_FALSE</option><option>SHORT_ANSWER</option></select></div><div class="col-md-2"><button class="btn btn-light w-100" :disabled="loading"><span v-if="loading" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-search"></i> Tìm kiếm</button></div></form></div>
    <div class="app-card p-2"><div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>Câu hỏi</th><th>Loại</th><th>Độ khó</th><th>Điểm</th><th>Trạng thái</th><th class="text-end">Thao tác</th></tr></thead><tbody><tr v-for="q in questions" :key="q.id"><td><strong>{{ q.text }}</strong><small class="d-block text-secondary">Cập nhật {{ formatDate(q.updatedAt) }}</small></td><td><span class="badge badge-soft-primary">{{ q.type }}</span></td><td><span :class="['badge',difficultyClass(q.difficulty)]">{{ difficultyLabel(q.difficulty) }}</span></td><td>{{ q.score }}</td><td><span :class="['badge',q.status==='ACTIVE'?'badge-soft-success':'badge-soft-warning']">{{ q.status==='ACTIVE'?'Hoạt động':'Tạm ẩn' }}</span></td><td class="text-end"><button class="btn btn-light btn-sm" title="Chỉnh sửa" @click="editQuestion(q.id)"><i class="bi bi-pencil"></i></button></td></tr><tr v-if="!loading&&!questions.length"><td colspan="6" class="text-center text-secondary py-5">Không có câu hỏi phù hợp.</td></tr></tbody></table></div></div>

    <div v-if="editorOpen" class="editor-backdrop" @click.self="editorOpen=false">
      <form class="editor-dialog app-card" @submit.prevent="saveQuestion">
        <div class="d-flex justify-content-between align-items-start gap-3 mb-3"><div><small class="editor-kicker">{{ editingId ? 'CHỈNH SỬA CÂU HỎI' : 'TẠO CÂU HỎI' }}</small><h2 class="h4 fw-bold mb-0">Nội dung và đáp án</h2></div><button type="button" class="btn btn-light btn-sm" @click="editorOpen=false"><i class="bi bi-x-lg"></i></button></div>
        <div class="row g-3">
          <div class="col-12"><label class="form-label">Nội dung câu hỏi</label><textarea v-model.trim="form.questionText" class="form-control" rows="3" required></textarea></div>
          <div class="col-md-4"><label class="form-label">Loại câu hỏi</label><select v-model="form.questionType" class="form-select" @change="normalizeAnswers"><option>SINGLE_CHOICE</option><option>MULTIPLE_CHOICE</option><option>TRUE_FALSE</option><option>SHORT_ANSWER</option></select></div>
          <div class="col-md-3"><label class="form-label">Độ khó</label><select v-model="form.difficulty" class="form-select"><option value="EASY">Dễ</option><option value="MEDIUM">Trung bình</option><option value="HARD">Khó</option></select></div>
          <div class="col-md-2"><label class="form-label">Điểm</label><input v-model.number="form.defaultScore" class="form-control" type="number" min="0" max="10000"></div>
          <div class="col-md-3"><label class="form-label">Trạng thái</label><select v-model="form.status" class="form-select"><option value="ACTIVE">Hoạt động</option><option value="INACTIVE">Tạm ẩn</option></select></div>
          <div class="col-12"><label class="form-label">Giải thích đáp án</label><textarea v-model="form.explanation" class="form-control" rows="2"></textarea></div>
        </div>

        <div v-if="form.questionType!=='SHORT_ANSWER'" class="answer-panel mt-4">
          <div class="d-flex justify-content-between align-items-center mb-2"><h3 class="h6 fw-bold mb-0">Các phương án</h3><button type="button" class="btn btn-light btn-sm" @click="addOption"><i class="bi bi-plus-lg"></i> Thêm phương án</button></div>
          <div v-for="(option,index) in form.options" :key="option.localKey" class="option-row"><input v-if="form.questionType==='MULTIPLE_CHOICE'" v-model="option.isCorrect" type="checkbox" class="form-check-input"><input v-else type="radio" name="correct-option" class="form-check-input" :checked="option.isCorrect" @change="selectCorrect(index)"><input v-model.trim="option.optionCode" class="form-control option-code" required><input v-model.trim="option.optionText" class="form-control" placeholder="Nội dung phương án" required><button type="button" class="btn btn-light btn-sm" :disabled="form.options.length<=2" @click="removeOption(index)"><i class="bi bi-trash"></i></button></div>
        </div>

        <div v-else class="answer-panel mt-4">
          <div class="row g-3"><div class="col-md-4"><label class="form-label">Cách chấm</label><select v-model="form.shortAnswerMode" class="form-select"><option value="EXACT_MATCH">Khớp chính xác</option><option value="CONTAINS">Có chứa đáp án</option><option value="MANUAL_REVIEW">Giảng viên chấm</option></select></div><div v-if="form.shortAnswerMode!=='MANUAL_REVIEW'" class="col-md-8"><label class="form-label">Đáp án mẫu</label><input v-model.trim="shortAnswer" class="form-control" required></div></div>
        </div>

        <div class="d-flex justify-content-end gap-2 mt-4"><button type="button" class="btn btn-light" @click="editorOpen=false">Hủy</button><button class="btn btn-brand" :disabled="saving"><span v-if="saving" class="spinner-border spinner-border-sm me-1"></span><i v-else class="bi bi-check-lg"></i> Lưu câu hỏi</button></div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { onMounted,reactive,ref } from 'vue'
import axiosClient from '../../api/axiosClient'

const search=ref(''),type=ref(''),questions=ref([]),loading=ref(false),saving=ref(false),editorOpen=ref(false),editingId=ref(0),message=ref(''),messageType=ref('success'),shortAnswer=ref('')
const pick=(source,...names)=>names.map(name=>source?.[name]).find(value=>value!==undefined&&value!==null)
const form=reactive(blankQuestion())

onMounted(loadQuestions)
function blankQuestion(){return{questionType:'SINGLE_CHOICE',questionText:'',description:'',explanation:'',difficulty:'EASY',defaultScore:10,shortAnswerMode:null,status:'ACTIVE',options:[newOption('A','',true,1),newOption('B','',false,2)],answerKeys:[]}}
function newOption(code,text,isCorrect,sortOrder){return{localKey:`${Date.now()}-${Math.random()}`,optionCode:code,optionText:text,isCorrect,sortOrder}}
async function loadQuestions(){loading.value=true;message.value='';try{const data=await axiosClient.get('/questions',{params:{search:search.value||undefined,type:type.value||undefined,pageSize:100,_fresh:Date.now()}});const rows=pick(data,'items','Items')||[];questions.value=rows.map(row=>({id:Number(pick(row,'Id','id')),text:pick(row,'QuestionText','questionText')||'',type:pick(row,'QuestionType','questionType')||'',difficulty:pick(row,'Difficulty','difficulty')||'EASY',score:Number(pick(row,'DefaultScore','defaultScore')||0),status:pick(row,'Status','status')||'ACTIVE',updatedAt:pick(row,'UpdatedAt','updatedAt','CreatedAt','createdAt')}))}catch(error){showMessage(error.message,'danger')}finally{loading.value=false}}
function createQuestion(){editingId.value=0;Object.assign(form,blankQuestion());shortAnswer.value='';editorOpen.value=true}
async function editQuestion(id){message.value='';try{const data=await axiosClient.get(`/questions/${id}`,{params:{_fresh:Date.now()}});const q=pick(data,'question','Question')||{};const options=pick(data,'options','Options')||[];const keys=pick(data,'answerKeys','AnswerKeys')||[];editingId.value=id;Object.assign(form,{questionType:pick(q,'QuestionType','questionType')||'SINGLE_CHOICE',questionText:pick(q,'QuestionText','questionText')||'',description:pick(q,'Description','description')||'',explanation:pick(q,'Explanation','explanation')||'',difficulty:pick(q,'Difficulty','difficulty')||'EASY',defaultScore:Number(pick(q,'DefaultScore','defaultScore')||0),shortAnswerMode:pick(q,'ShortAnswerMode','shortAnswerMode'),status:pick(q,'Status','status')||'ACTIVE',options:options.map((o,index)=>newOption(pick(o,'OptionCode','optionCode')||String.fromCharCode(65+index),pick(o,'OptionText','optionText')||'',Boolean(pick(o,'IsCorrect','isCorrect')),Number(pick(o,'SortOrder','sortOrder')||index+1))),answerKeys:keys.map((k,index)=>({answerText:pick(k,'AnswerText','answerText')||'',isCaseSensitive:Boolean(pick(k,'IsCaseSensitive','isCaseSensitive')),sortOrder:Number(pick(k,'SortOrder','sortOrder')||index+1)}))});shortAnswer.value=form.answerKeys[0]?.answerText||'';editorOpen.value=true}catch(error){showMessage(error.message,'danger')}}
async function saveQuestion(){saving.value=true;message.value='';try{const isShort=form.questionType==='SHORT_ANSWER';const body={questionType:form.questionType,questionText:form.questionText,description:form.description||null,explanation:form.explanation||null,difficulty:form.difficulty,defaultScore:Number(form.defaultScore)||0,shortAnswerMode:isShort?(form.shortAnswerMode||'EXACT_MATCH'):null,status:form.status,options:isShort?[]:form.options.map((o,index)=>({optionCode:o.optionCode,optionText:o.optionText,isCorrect:o.isCorrect,sortOrder:index+1})),answerKeys:isShort&&form.shortAnswerMode!=='MANUAL_REVIEW'?[{answerText:shortAnswer.value,isCaseSensitive:false,sortOrder:1}]:[]};if(editingId.value)await axiosClient.put(`/questions/${editingId.value}`,body);else await axiosClient.post('/questions',body);editorOpen.value=false;await loadQuestions();showMessage('Đã lưu câu hỏi vào SQL. Video interaction và Preview sẽ đọc nội dung mới ngay lập tức.')}catch(error){showMessage(error.message,'danger')}finally{saving.value=false}}
function normalizeAnswers(){if(form.questionType==='TRUE_FALSE')form.options=[newOption('A','Đúng',true,1),newOption('B','Sai',false,2)];else if(form.questionType==='SHORT_ANSWER'){form.shortAnswerMode=form.shortAnswerMode||'EXACT_MATCH'}else if(form.options.length<2)form.options=[newOption('A','',true,1),newOption('B','',false,2)];if(form.questionType==='SINGLE_CHOICE')selectCorrect(form.options.findIndex(o=>o.isCorrect)>=0?form.options.findIndex(o=>o.isCorrect):0)}
function selectCorrect(index){if(form.questionType!=='MULTIPLE_CHOICE')form.options.forEach((option,i)=>option.isCorrect=i===index)}
function addOption(){form.options.push(newOption(String.fromCharCode(65+form.options.length),'',false,form.options.length+1))}
function removeOption(index){if(form.options.length>2)form.options.splice(index,1)}
function showMessage(text,type='success'){message.value=text;messageType.value=type}
function difficultyLabel(value){return{EASY:'Dễ',MEDIUM:'Trung bình',HARD:'Khó'}[value]||value}
function difficultyClass(value){return value==='EASY'?'badge-soft-success':value==='HARD'?'badge-soft-danger':'badge-soft-warning'}
function formatDate(value){return value?new Intl.DateTimeFormat('vi-VN').format(new Date(value)):'—'}
</script>

<style scoped>
.editor-backdrop{position:fixed;inset:0;background:rgba(5,24,35,.68);z-index:1080;display:grid;place-items:center;padding:1.5rem}.editor-dialog{width:min(900px,96vw);max-height:92vh;overflow:auto;padding:1.5rem}.editor-kicker{color:#07875a;font-weight:850;letter-spacing:.04em}.answer-panel{background:#f3f8f6;border-radius:10px;padding:1rem}.option-row{display:grid;grid-template-columns:24px 72px 1fr auto;align-items:center;gap:.65rem;margin-top:.65rem}.option-row .form-check-input{margin:0}.option-code{text-align:center;font-weight:800}@media(max-width:640px){.option-row{grid-template-columns:24px 56px 1fr}.option-row button{grid-column:3;justify-self:end}}
</style>
