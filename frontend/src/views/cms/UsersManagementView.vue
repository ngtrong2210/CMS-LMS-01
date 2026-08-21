<template>
  <section class="system-page">
    <AppPageHeader
      title="Quản lý người dùng"
      description="Tạo tài khoản, gán vai trò và kiểm soát trạng thái truy cập."
      eyebrow="Quản trị hệ thống"
      icon="bi-person-gear"
      :breadcrumbs="breadcrumbs"
    >
      <template #actions>
        <button type="button" class="btn btn-action-create" @click="openCreate">
          <i class="bi bi-person-plus"></i> Thêm người dùng
        </button>
      </template>
    </AppPageHeader>

    <AppFilterBar>
      <label class="system-filter-field system-filter-field--search">
        <span>Tìm kiếm</span>
        <span class="system-search-control">
          <i class="bi bi-search"></i>
          <input
            v-model="filters.search"
            class="form-control"
            placeholder="Tên, tài khoản hoặc email..."
            @keydown.enter="loadUsers"
          />
        </span>
      </label>
      <label class="system-filter-field">
        <span>Vai trò</span>
        <select v-model="filters.roleCode" class="form-select" aria-label="Lọc vai trò">
          <option value="">Tất cả vai trò</option>
          <option v-for="role in roles" :key="role.roleId" :value="role.code">{{ role.name }}</option>
        </select>
      </label>
      <label class="system-filter-field">
        <span>Trạng thái</span>
        <select v-model="filters.status" class="form-select" aria-label="Lọc trạng thái">
          <option value="">Tất cả trạng thái</option>
          <option value="ACTIVE">Đang hoạt động</option>
          <option value="INACTIVE">Ngừng hoạt động</option>
          <option value="LOCKED">Đã khóa</option>
        </select>
      </label>
      <template #actions>
        <button type="button" class="btn btn-action-filter" :disabled="loading" @click="loadUsers">
          <span v-if="loading" class="spinner-border spinner-border-sm"></span>
          <i v-else class="bi bi-funnel"></i> Áp dụng
        </button>
      </template>
    </AppFilterBar>

    <div v-if="message" class="alert alert-success system-alert"><i class="bi bi-check-circle"></i>{{ message }}</div>
    <div v-if="error" class="alert alert-danger system-alert">
      <i class="bi bi-exclamation-triangle"></i>{{ error }}
    </div>

    <div class="app-card system-table-card">
      <header class="system-data-header">
        <div>
          <span>Danh sách tài khoản</span>
          <small>{{ paging.totalItems }} người dùng trong hệ thống</small>
        </div>
        <span class="system-data-count">{{ users.length }} kết quả trang này</span>
      </header>

      <AppLoading
        v-if="loading"
        title="Đang tải người dùng"
        description="Hệ thống đang đồng bộ danh sách tài khoản và vai trò."
      />
      <AppEmptyState
        v-else-if="!users.length"
        icon="bi-person-x"
        title="Không tìm thấy người dùng"
        description="Thử thay đổi từ khóa hoặc bộ lọc để xem thêm kết quả."
      />
      <div v-else class="table-responsive system-table-scroll">
        <table class="table align-middle mb-0">
          <thead>
            <tr>
              <th scope="col" class="system-index-heading">STT</th>
              <th scope="col">Người dùng</th>
              <th scope="col">Vai trò</th>
              <th scope="col" class="system-column-code">Mã nghiệp vụ</th>
              <th scope="col">Trạng thái</th>
              <th scope="col" class="system-column-date">Lần đăng nhập cuối</th>
              <th scope="col" class="system-action-heading">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(user, index) in users" :key="user.userId">
              <td class="system-index-cell">{{ (paging.page - 1) * paging.pageSize + index + 1 }}</td>
              <td>
                <div class="system-user-cell">
                  <span class="avatar">{{ initials(user.fullName) }}</span>
                  <div>
                    <strong>{{ user.fullName }}</strong>
                    <small>{{ user.username }} · {{ user.email }}</small>
                  </div>
                </div>
              </td>
              <td>
                <span class="badge badge-soft-primary">{{ user.roleNames }}</span>
              </td>
              <td class="system-column-code">{{ user.teacherCode || user.studentCode || '—' }}</td>
              <td>
                <span :class="['badge', statusMeta(user.status).className]">{{ statusMeta(user.status).label }}</span>
              </td>
              <td class="system-column-date">{{ formatDate(user.lastLoginAt) }}</td>
              <td class="system-action-cell">
                <div class="system-row-actions">
                  <button
                    type="button"
                    class="user-action-button is-edit"
                    title="Sửa thông tin người dùng"
                    @click="openEdit(user.userId)"
                  >
                    <i class="bi bi-pencil-square"></i> Sửa
                  </button>
                  <button
                    type="button"
                    :class="['user-action-button', user.status === 'ACTIVE' ? 'is-lock' : 'is-unlock']"
                    :title="user.status === 'ACTIVE' ? 'Khóa quyền đăng nhập' : 'Mở lại quyền đăng nhập'"
                    @click="toggleStatus(user)"
                  >
                    <i :class="['bi', user.status === 'ACTIVE' ? 'bi-lock' : 'bi-unlock']"></i>
                    {{ user.status === 'ACTIVE' ? 'Khóa' : 'Mở khóa' }}
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AppPagination
        v-if="!loading"
        :page="paging.page"
        :total-pages="totalPages"
        :shown-count="users.length"
        :total-items="paging.totalItems"
        @previous="changePage(-1)"
        @next="changePage(1)"
      />
    </div>

    <Teleport to="body">
      <div v-if="modalOpen" class="system-modal-backdrop" @click.self="closeModal">
        <form
          class="system-modal"
          role="dialog"
          aria-modal="true"
          aria-labelledby="system-user-modal-title"
          @submit.prevent="saveUser"
        >
          <header class="system-modal-header">
            <div>
              <small><i class="bi bi-person-vcard"></i> Thông tin tài khoản</small>
              <h2 id="system-user-modal-title">{{ editingUserID ? 'Cập nhật người dùng' : 'Thêm người dùng mới' }}</h2>
              <p>Thông tin được dùng để đăng nhập và phân quyền trong hệ thống.</p>
            </div>
            <button type="button" class="system-modal-close" aria-label="Đóng" @click="closeModal">
              <i class="bi bi-x-lg"></i>
            </button>
          </header>
          <div class="system-form-grid">
            <label
              ><span>Tên đăng nhập *</span
              ><input
                v-model.trim="form.username"
                class="form-control"
                required
                minlength="3"
                :disabled="Boolean(editingUserID)"
            /></label>
            <label><span>Họ và tên *</span><input v-model.trim="form.fullName" class="form-control" required /></label>
            <label
              ><span>Email *</span><input v-model.trim="form.email" type="email" class="form-control" required
            /></label>
            <label>
              <span>{{ editingUserID ? 'Mật khẩu mới' : 'Mật khẩu *' }}</span>
              <input
                v-model="form.password"
                type="password"
                class="form-control"
                :required="!editingUserID"
                minlength="6"
                :placeholder="editingUserID ? 'Để trống nếu không đổi' : 'Tối thiểu 6 ký tự'"
              />
            </label>
            <label
              ><span>Mã giảng viên</span
              ><input v-model.trim="form.teacherCode" class="form-control" placeholder="Ví dụ: GV0001"
            /></label>
            <label
              ><span>Mã học viên</span
              ><input v-model.trim="form.studentCode" class="form-control" placeholder="Ví dụ: HV0001"
            /></label>
            <label
              ><span>Trạng thái</span
              ><select v-model="form.status" class="form-select">
                <option value="ACTIVE">Đang hoạt động</option>
                <option value="INACTIVE">Ngừng hoạt động</option>
                <option value="LOCKED">Đã khóa</option>
              </select></label
            >
          </div>
          <fieldset class="system-role-fieldset">
            <legend>Vai trò được cấp *</legend>
            <label v-for="role in roles" :key="role.roleId" class="system-check-card">
              <input v-model="form.roleCodes" type="checkbox" :value="role.code" />
              <span
                ><i :class="['bi', roleIcon(role.code)]"></i><strong>{{ role.name }}</strong
                ><small>{{ role.code }}</small></span
              >
            </label>
          </fieldset>
          <p v-if="formError" class="system-form-error"><i class="bi bi-exclamation-circle"></i>{{ formError }}</p>
          <footer class="system-modal-actions">
            <button type="button" class="btn btn-action-cancel" @click="closeModal">
              <i class="bi bi-x-lg"></i> Hủy
            </button>
            <button type="submit" class="btn btn-action-save" :disabled="saving">
              <i class="bi bi-check-lg"></i> {{ saving ? 'Đang lưu...' : 'Lưu người dùng' }}
            </button>
          </footer>
        </form>
      </div>
    </Teleport>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import AppFilterBar from '../../components/data/AppFilterBar.vue'
import AppEmptyState from '../../components/feedback/AppEmptyState.vue'
import AppLoading from '../../components/feedback/AppLoading.vue'
import AppPageHeader from '../../components/navigation/AppPageHeader.vue'
import AppPagination from '../../components/navigation/AppPagination.vue'
import systemAdministrationService from '../../services/systemAdministrationService'
import { confirmDialog } from '../../utils/confirmDialog'

defineOptions({ name: 'UsersManagementView' })

const roles = ref([])
const users = ref([])
const loading = ref(false)
const saving = ref(false)
const modalOpen = ref(false)
const editingUserID = ref(null)
const message = ref('')
const error = ref('')
const formError = ref('')
const filters = reactive({ search: '', roleCode: '', status: '' })
const paging = reactive({ page: 1, pageSize: 20, totalItems: 0 })
const breadcrumbs = [{ label: 'Tổng quan', to: '/cms/dashboard' }, { label: 'Hệ thống' }, { label: 'Người dùng' }]
const blankForm = () => ({
  username: '',
  password: '',
  fullName: '',
  email: '',
  studentCode: '',
  teacherCode: '',
  avatarUrl: '',
  status: 'ACTIVE',
  roleCodes: []
})
const form = reactive(blankForm())
const totalPages = computed(() => Math.max(1, Math.ceil(paging.totalItems / paging.pageSize)))

onMounted(async () => {
  await Promise.all([loadRoles(), loadUsers()])
})

async function loadRoles() {
  try {
    roles.value = await systemAdministrationService.getRoles()
  } catch (requestError) {
    error.value = requestError.message
  }
}

async function loadUsers() {
  loading.value = true
  error.value = ''
  try {
    const result = await systemAdministrationService.getUsers({
      ...filters,
      page: paging.page,
      pageSize: paging.pageSize
    })
    users.value = result.items || []
    paging.totalItems = result.totalItems || 0
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    loading.value = false
  }
}

function openCreate() {
  Object.assign(form, blankForm())
  editingUserID.value = null
  formError.value = ''
  modalOpen.value = true
}

async function openEdit(userId) {
  formError.value = ''
  try {
    const result = await systemAdministrationService.getUser(userId)
    Object.assign(form, blankForm(), result.user, { password: '', roleCodes: result.roleCodes || [] })
    editingUserID.value = userId
    modalOpen.value = true
  } catch (requestError) {
    error.value = requestError.message
  }
}

function closeModal() {
  modalOpen.value = false
}

async function saveUser() {
  if (!form.roleCodes.length) {
    formError.value = 'Hãy chọn ít nhất một vai trò.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload = {
      ...form,
      studentCode: form.studentCode || null,
      teacherCode: form.teacherCode || null,
      avatarUrl: form.avatarUrl || null
    }
    if (editingUserID.value) await systemAdministrationService.updateUser(editingUserID.value, payload)
    else await systemAdministrationService.createUser(payload)
    message.value = editingUserID.value ? 'Đã cập nhật người dùng.' : 'Đã tạo người dùng mới.'
    closeModal()
    await loadUsers()
  } catch (requestError) {
    formError.value = requestError.message
  } finally {
    saving.value = false
  }
}

async function toggleStatus(user) {
  const activating = user.status !== 'ACTIVE'
  const confirmed = await confirmDialog({
    title: activating ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
    message: `${activating ? 'Cho phép' : 'Ngăn'} “${user.fullName}” đăng nhập hệ thống?`,
    confirmText: activating ? 'Mở khóa' : 'Khóa tài khoản',
    tone: activating ? 'success' : 'danger',
    icon: activating ? 'bi-unlock' : 'bi-lock'
  })
  if (!confirmed) return
  try {
    await systemAdministrationService.setUserStatus(user.userId, activating ? 'ACTIVE' : 'LOCKED')
    message.value = activating ? 'Đã mở khóa tài khoản.' : 'Đã khóa tài khoản.'
    await loadUsers()
  } catch (requestError) {
    error.value = requestError.message
  }
}

function changePage(offset) {
  paging.page += offset
  loadUsers()
}
function initials(name = '') {
  return (
    name
      .split(' ')
      .filter(Boolean)
      .slice(-2)
      .map((part) => part[0])
      .join('')
      .toUpperCase() || 'U'
  )
}
function formatDate(value) {
  return value
    ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
    : 'Chưa đăng nhập'
}
function roleIcon(code) {
  return { ADMIN: 'bi-shield-lock', TEACHER: 'bi-person-video3', STUDENT: 'bi-mortarboard' }[code] || 'bi-person-badge'
}
function statusMeta(status) {
  return (
    {
      ACTIVE: { label: 'Đang hoạt động', className: 'badge-soft-success' },
      INACTIVE: { label: 'Ngừng hoạt động', className: 'badge-soft-warning' },
      LOCKED: { label: 'Đã khóa', className: 'badge-soft-danger' }
    }[status] || { label: status, className: 'badge-soft-warning' }
  )
}
</script>

<style scoped src="../../assets/css/pages/cms/system-management.css"></style>
