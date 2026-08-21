<template>
  <section class="lesson-discussion" aria-labelledby="lesson-discussion-title">
    <div class="discussion-heading">
      <div>
        <span>TRAO ĐỔI BÀI HỌC</span>
        <h2 id="lesson-discussion-title">Thảo luận</h2>
        <p>Đặt câu hỏi, trao đổi nội dung và nhận phản hồi từ giảng viên.</p>
      </div>
      <strong>{{ totalCommentCount }} bình luận</strong>
    </div>

    <form class="discussion-composer" @submit.prevent="createComment">
      <textarea
        v-model.trim="newContent"
        class="form-control"
        rows="4"
        maxlength="5000"
        placeholder="Viết câu hỏi hoặc chia sẻ của bạn về bài học..."
      ></textarea>
      <div>
        <small>{{ newContent.length }}/5000</small>
        <button class="btn-comment-primary" :disabled="busy || !newContent">
          <span v-if="busy" class="spinner-border spinner-border-sm"></span>
          <i v-else class="bi bi-send-fill"></i> Đăng bình luận
        </button>
      </div>
    </form>

    <div v-if="loading" class="discussion-state">
      <span class="spinner-border spinner-border-sm"></span> Đang tải thảo luận...
    </div>
    <div v-else-if="error" class="discussion-state error">
      <i class="bi bi-exclamation-circle"></i> {{ error }}
      <button type="button" @click="loadComments">Thử lại</button>
    </div>
    <div v-else-if="!comments.length" class="discussion-empty">
      <i class="bi bi-chat-square-text"></i>
      <strong>Chưa có thảo luận</strong>
      <span>Hãy là người đầu tiên đặt câu hỏi cho bài học này.</span>
    </div>
    <div v-else class="discussion-list">
      <LessonCommentItem
        v-for="comment in comments"
        :key="comment.id"
        :comment="comment"
        @reply="createReply"
        @edit="updateComment"
        @delete="requestDelete"
      />
    </div>

    <button v-if="comments.length < rootCommentCount" type="button" class="discussion-load-more" @click="loadMore">
      Xem thêm thảo luận
    </button>

    <div v-if="deleteTarget" class="app-modal-backdrop" @click.self="deleteTarget = null">
      <div class="app-confirm-modal" role="dialog" aria-modal="true" aria-labelledby="delete-comment-title">
        <span class="confirm-icon danger"><i class="bi bi-trash3"></i></span>
        <small>Xác nhận thao tác</small>
        <h3 id="delete-comment-title">Xóa bình luận?</h3>
        <p>Các câu trả lời phía dưới vẫn được giữ lại để không làm mất mạch thảo luận.</p>
        <div>
          <button type="button" class="btn-comment-plain" @click="deleteTarget = null">Hủy</button>
          <button type="button" class="btn-comment-danger" @click="deleteComment">Xóa bình luận</button>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { onMounted, ref, watch } from 'vue'
import axiosClient from '../../api/axiosClient'
import LessonCommentItem from './LessonCommentItem.vue'
import '../../assets/css/pages/lms/lesson-discussion.css'

const props = defineProps({ lessonId: { type: Number, required: true } })
const emit = defineEmits(['count-change'])
const comments = ref([])
const loading = ref(true)
const busy = ref(false)
const error = ref('')
const newContent = ref('')
const page = ref(1)
const pageSize = 20
const rootCommentCount = ref(0)
const totalCommentCount = ref(0)
const deleteTarget = ref(null)

onMounted(loadComments)
watch(
  () => props.lessonId,
  () => {
    comments.value = []
    newContent.value = ''
    page.value = 1
    void loadComments()
  }
)

async function loadComments() {
  if (!props.lessonId) return
  loading.value = true
  error.value = ''
  try {
    const feed = await axiosClient.get(`/lms/lessons/${props.lessonId}/comments`, {
      params: { page: page.value, pageSize }
    })
    comments.value = feed.items || feed.Items || []
    rootCommentCount.value = Number(feed.rootCommentCount ?? feed.RootCommentCount ?? 0)
    totalCommentCount.value = Number(feed.totalCommentCount ?? feed.TotalCommentCount ?? 0)
    emit('count-change', totalCommentCount.value)
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    loading.value = false
  }
}

async function runMutation(action) {
  busy.value = true
  error.value = ''
  try {
    await action()
    await loadComments()
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    busy.value = false
  }
}

async function createComment() {
  const content = newContent.value
  if (!content) return
  await runMutation(() => axiosClient.post(`/lms/lessons/${props.lessonId}/comments`, { content }))
  if (!error.value) newContent.value = ''
}

async function createReply(payload) {
  await runMutation(() => axiosClient.post(`/lms/lessons/${props.lessonId}/comments`, payload))
}

async function updateComment(payload) {
  await runMutation(() => axiosClient.put(`/lms/comments/${payload.id}`, { content: payload.content }))
}

function requestDelete(comment) {
  deleteTarget.value = comment
}

async function deleteComment() {
  const target = deleteTarget.value
  if (!target) return
  deleteTarget.value = null
  await runMutation(() => axiosClient.delete(`/lms/comments/${target.id}`))
}

async function loadMore() {
  page.value += 1
  loading.value = true
  try {
    const feed = await axiosClient.get(`/lms/lessons/${props.lessonId}/comments`, {
      params: { page: page.value, pageSize }
    })
    comments.value = [...comments.value, ...(feed.items || feed.Items || [])]
    rootCommentCount.value = Number(feed.rootCommentCount ?? feed.RootCommentCount ?? 0)
    totalCommentCount.value = Number(feed.totalCommentCount ?? feed.TotalCommentCount ?? 0)
    emit('count-change', totalCommentCount.value)
  } catch (requestError) {
    page.value -= 1
    error.value = requestError.message
  } finally {
    loading.value = false
  }
}
</script>
