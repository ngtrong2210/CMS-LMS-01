<template>
  <article :class="['lesson-comment', `comment-depth-${Math.min(depth, 2)}`, { deleted: comment.isDeleted }]">
    <div class="comment-avatar" aria-hidden="true">
      <img v-if="comment.userAvatarUrl" :src="comment.userAvatarUrl" alt="" />
      <span v-else>{{ initials(comment.userFullName) }}</span>
    </div>
    <div class="comment-body">
      <header>
        <div>
          <strong>{{ comment.userFullName }}</strong>
          <span :class="['comment-role', `role-${comment.userRole.toLowerCase()}`]">{{
            roleLabel(comment.userRole)
          }}</span>
        </div>
        <time :datetime="comment.createdDate">{{ relativeTime(comment.createdDate) }}</time>
      </header>

      <template v-if="editing">
        <textarea v-model.trim="editContent" class="form-control" rows="3" maxlength="5000"></textarea>
        <div class="comment-editor-actions">
          <button type="button" class="btn-comment-plain" @click="cancelEdit">Hủy</button>
          <button type="button" class="btn-comment-primary" :disabled="!editContent" @click="saveEdit">
            Lưu thay đổi
          </button>
        </div>
      </template>
      <p v-else class="comment-content">{{ comment.content }}</p>

      <div v-if="!comment.isDeleted && !editing" class="comment-actions">
        <button type="button" @click="replying = !replying"><i class="bi bi-reply"></i> Trả lời</button>
        <button v-if="comment.canEdit" type="button" @click="beginEdit"><i class="bi bi-pencil"></i> Sửa</button>
        <button v-if="comment.canDelete" type="button" class="danger" @click="$emit('delete', comment)">
          <i class="bi bi-trash3"></i> Xóa
        </button>
        <span v-if="comment.isEdited">Đã chỉnh sửa</span>
      </div>

      <form v-if="replying" class="comment-reply-form" @submit.prevent="submitReply">
        <textarea
          v-model.trim="replyContent"
          class="form-control"
          rows="3"
          maxlength="5000"
          :placeholder="`Trả lời ${comment.userFullName}...`"
        ></textarea>
        <div>
          <button type="button" class="btn-comment-plain" @click="cancelReply">Hủy</button>
          <button class="btn-comment-primary" :disabled="!replyContent">Gửi trả lời</button>
        </div>
      </form>

      <div v-if="comment.replies?.length" class="comment-replies">
        <LessonCommentItem
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :depth="depth + 1"
          @reply="$emit('reply', $event)"
          @edit="$emit('edit', $event)"
          @delete="$emit('delete', $event)"
        />
      </div>
    </div>
  </article>
</template>

<script setup>
import { ref } from 'vue'

defineOptions({ name: 'LessonCommentItem' })
const props = defineProps({
  comment: { type: Object, required: true },
  depth: { type: Number, default: 0 }
})
const emit = defineEmits(['reply', 'edit', 'delete'])
const replying = ref(false)
const editing = ref(false)
const replyContent = ref('')
const editContent = ref('')

function initials(name) {
  return String(name || 'HV')
    .trim()
    .split(/\s+/)
    .slice(-2)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
}

function roleLabel(role) {
  return { ADMIN: 'Quản trị', TEACHER: 'Giảng viên', STUDENT: 'Học viên' }[role] || 'Thành viên'
}

function relativeTime(value) {
  const date = new Date(value)
  const seconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000))
  if (seconds < 60) return 'Vừa xong'
  if (seconds < 3600) return `${Math.floor(seconds / 60)} phút trước`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)} giờ trước`
  if (seconds < 604800) return `${Math.floor(seconds / 86400)} ngày trước`
  return new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(date)
}

function submitReply() {
  if (!replyContent.value) return
  emit('reply', { parentCommentId: props.comment.id, content: replyContent.value })
  replyContent.value = ''
  replying.value = false
}

function cancelReply() {
  replyContent.value = ''
  replying.value = false
}

function beginEdit() {
  editContent.value = props.comment.content
  editing.value = true
}

function cancelEdit() {
  editContent.value = ''
  editing.value = false
}

function saveEdit() {
  if (!editContent.value) return
  emit('edit', { id: props.comment.id, content: editContent.value })
  editing.value = false
}
</script>
