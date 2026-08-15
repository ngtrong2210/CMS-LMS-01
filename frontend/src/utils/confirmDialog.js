import { reactive } from 'vue'

const defaults = {
  open: false,
  title: 'Xác nhận thao tác',
  message: '',
  confirmText: 'Xác nhận',
  cancelText: 'Hủy',
  tone: 'primary',
  icon: 'bi-question-lg'
}

export const confirmDialogState = reactive({ ...defaults })

let pendingResolver = null

export function confirmDialog(options = {}) {
  if (pendingResolver) pendingResolver(false)

  Object.assign(confirmDialogState, defaults, typeof options === 'string' ? { message: options } : options, {
    open: true
  })

  return new Promise((resolve) => {
    pendingResolver = resolve
  })
}

export function closeConfirmDialog(confirmed = false) {
  if (!confirmDialogState.open) return

  confirmDialogState.open = false
  const resolve = pendingResolver
  pendingResolver = null
  resolve?.(confirmed)
}
