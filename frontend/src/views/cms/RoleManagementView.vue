<template>
  <section>
    <header class="system-page-header">
      <div>
        <span class="system-kicker"><i class="bi bi-shield-check"></i> Kiểm soát truy cập</span>
        <h1 class="page-title mb-1">Vai trò và phân quyền</h1>
        <p class="page-subtitle mb-0">Quản lý chính xác chức năng mà từng nhóm người dùng được phép sử dụng.</p>
      </div>
      <CmsPageActions>
        <button
          type="button"
          class="btn btn-action-save"
          :disabled="!selectedRole || selectedRole.code === 'ADMIN' || saving"
          @click="savePermissions"
        >
          <i class="bi bi-check2-circle"></i> {{ saving ? 'Đang lưu...' : 'Lưu phân quyền' }}
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" class="alert alert-success system-alert"><i class="bi bi-check-circle"></i>{{ message }}</div>
    <div v-if="error" class="alert alert-danger system-alert">
      <i class="bi bi-exclamation-triangle"></i>{{ error }}
    </div>

    <div class="role-layout">
      <aside class="app-card role-list-card">
        <header>
          <h2>Nhóm vai trò</h2>
          <small>{{ roles.length }} vai trò hệ thống</small>
        </header>
        <button
          v-for="role in roles"
          :key="role.roleId"
          type="button"
          :class="['role-card-button', { active: selectedRole?.roleId === role.roleId }]"
          @click="selectRole(role)"
        >
          <i :class="['bi', roleIcon(role.code)]"></i>
          <span
            ><strong>{{ role.name }}</strong
            ><small>{{ role.userCount }} người dùng · {{ role.permissionCount }} quyền</small></span
          >
          <i class="bi bi-chevron-right"></i>
        </button>
      </aside>

      <div class="app-card permission-panel">
        <header class="permission-panel-header">
          <div>
            <span class="system-kicker">{{ selectedRole?.code || 'VAI TRÒ' }}</span>
            <h2>{{ selectedRole?.name || 'Chọn vai trò' }}</h2>
            <p v-if="selectedRole?.code === 'ADMIN'">Quản trị viên luôn có toàn bộ quyền để tránh khóa hệ thống.</p>
            <p v-else>Chọn các quyền cần cấp rồi nhấn “Lưu phân quyền”.</p>
          </div>
          <span v-if="selectedRole" class="permission-count"
            ><strong>{{ grantedCount }}</strong
            ><small>/ {{ permissions.length }} quyền</small></span
          >
        </header>
        <div v-if="loading" class="system-loading">
          <span class="spinner-border spinner-border-sm"></span> Đang tải quyền...
        </div>
        <div v-else class="permission-groups">
          <section v-for="group in permissionGroups" :key="group.module" class="permission-group">
            <header>
              <div>
                <i :class="['bi', moduleIcon(group.module)]"></i
                ><span
                  ><strong>{{ moduleName(group.module) }}</strong
                  ><small>{{ group.items.length }} chức năng</small></span
                >
              </div>
              <label v-if="selectedRole?.code !== 'ADMIN'" class="permission-toggle-all"
                ><input
                  type="checkbox"
                  :checked="group.items.every((item) => item.isGranted)"
                  @change="toggleGroup(group, $event.target.checked)"
                />
                Chọn nhóm</label
              >
            </header>
            <div class="permission-grid">
              <label
                v-for="permission in group.items"
                :key="permission.permissionId"
                :class="[
                  'permission-option',
                  { checked: permission.isGranted, disabled: selectedRole?.code === 'ADMIN' }
                ]"
              >
                <input v-model="permission.isGranted" type="checkbox" :disabled="selectedRole?.code === 'ADMIN'" />
                <span
                  ><strong>{{ permission.name }}</strong
                  ><small>{{ permission.code }}</small></span
                >
              </label>
            </div>
          </section>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import systemAdministrationService from '../../services/systemAdministrationService'

defineOptions({ name: 'RoleManagementView' })

const roles = ref([])
const permissions = ref([])
const selectedRole = ref(null)
const loading = ref(false)
const saving = ref(false)
const message = ref('')
const error = ref('')
const grantedCount = computed(() => permissions.value.filter((item) => item.isGranted).length)
const permissionGroups = computed(() =>
  Object.entries(Object.groupBy(permissions.value, (item) => item.module)).map(([module, items]) => ({ module, items }))
)

onMounted(async () => {
  try {
    roles.value = await systemAdministrationService.getRoles()
    await selectRole(roles.value.find((role) => role.code === 'TEACHER') || roles.value[0])
  } catch (requestError) {
    error.value = requestError.message
  }
})

async function selectRole(role) {
  if (!role) return
  selectedRole.value = role
  loading.value = true
  error.value = ''
  try {
    permissions.value = await systemAdministrationService.getRolePermissions(role.roleId)
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    loading.value = false
  }
}

async function savePermissions() {
  if (!selectedRole.value || selectedRole.value.code === 'ADMIN') return
  saving.value = true
  error.value = ''
  try {
    await systemAdministrationService.saveRolePermissions(
      selectedRole.value.roleId,
      permissions.value.filter((item) => item.isGranted).map((item) => item.code)
    )
    message.value = `Đã lưu quyền cho vai trò ${selectedRole.value.name}.`
    roles.value = await systemAdministrationService.getRoles()
    selectedRole.value = roles.value.find((role) => role.roleId === selectedRole.value.roleId)
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    saving.value = false
  }
}

function toggleGroup(group, checked) {
  group.items.forEach((item) => {
    item.isGranted = checked
  })
}
function roleIcon(code) {
  return { ADMIN: 'bi-shield-lock', TEACHER: 'bi-person-video3', STUDENT: 'bi-mortarboard' }[code] || 'bi-person-badge'
}
function moduleIcon(module) {
  return (
    {
      DASHBOARD: 'bi-grid',
      COURSE: 'bi-journal-bookmark',
      CHAPTER: 'bi-list-ol',
      LESSON: 'bi-play-btn',
      VIDEO: 'bi-camera-video',
      QUESTION: 'bi-patch-question',
      STUDENT: 'bi-people',
      ENROLLMENT: 'bi-person-plus',
      REPORT: 'bi-bar-chart',
      SYSTEM: 'bi-gear'
    }[module] || 'bi-box'
  )
}
function moduleName(module) {
  return (
    {
      DASHBOARD: 'Tổng quan',
      COURSE: 'Khóa học',
      CHAPTER: 'Chương',
      LESSON: 'Bài học',
      VIDEO: 'Video',
      QUESTION: 'Câu hỏi',
      STUDENT: 'Học viên',
      ENROLLMENT: 'Ghi danh',
      REPORT: 'Báo cáo',
      SYSTEM: 'Hệ thống'
    }[module] || module
  )
}
</script>

<style scoped src="../../assets/css/pages/cms/system-management.css"></style>
