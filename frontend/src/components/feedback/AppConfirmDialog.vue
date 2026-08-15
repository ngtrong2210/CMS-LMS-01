<template>
  <Teleport to="body">
    <Transition name="app-confirm-fade">
      <div v-if="state.open" class="app-confirm-backdrop" @click.self="cancel" @keydown.esc.prevent="cancel">
        <section
          ref="dialogRef"
          class="app-confirm-dialog"
          role="alertdialog"
          aria-modal="true"
          :aria-labelledby="titleId"
          :aria-describedby="messageId"
          tabindex="-1"
        >
          <button type="button" class="app-confirm-close" aria-label="Đóng hộp thoại" @click="cancel">
            <i class="bi bi-x-lg"></i>
          </button>

          <div :class="['app-confirm-icon', `is-${state.tone}`]">
            <i :class="['bi', state.icon]"></i>
          </div>

          <div class="app-confirm-copy">
            <small>Xác nhận thao tác</small>
            <h2 :id="titleId">{{ state.title }}</h2>
            <p :id="messageId">{{ state.message }}</p>
          </div>

          <div class="app-confirm-actions">
            <button type="button" class="btn btn-action-cancel" @click="cancel">
              <i class="bi bi-x-lg"></i> {{ state.cancelText }}
            </button>
            <button type="button" :class="['btn', 'app-confirm-submit', `is-${state.tone}`]" @click="accept">
              <i :class="['bi', state.icon]"></i> {{ state.confirmText }}
            </button>
          </div>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { nextTick, ref, watch } from 'vue'
import { closeConfirmDialog, confirmDialogState as state } from '../../utils/confirmDialog'

const dialogRef = ref(null)
const titleId = 'app-confirm-title'
const messageId = 'app-confirm-message'

watch(
  () => state.open,
  async (open) => {
    if (!open) return
    await nextTick()
    dialogRef.value?.focus()
  }
)

function cancel() {
  closeConfirmDialog(false)
}

function accept() {
  closeConfirmDialog(true)
}
</script>
