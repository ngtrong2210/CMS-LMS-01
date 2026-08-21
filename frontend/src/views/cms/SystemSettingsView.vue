<template>
  <section>
    <header class="system-page-header">
      <div>
        <span class="system-kicker"><i class="bi bi-gear"></i> Thiết lập vận hành</span>
        <h1 class="page-title mb-1">Cài đặt hệ thống</h1>
        <p class="page-subtitle mb-0">Cấu hình thông tin chung, quy tắc học tập và chính sách bảo mật.</p>
      </div>
      <CmsPageActions>
        <button type="button" class="btn btn-action-save" :disabled="loading || saving" @click="saveSettings">
          <i class="bi bi-floppy"></i> {{ saving ? 'Đang lưu...' : 'Lưu cài đặt' }}
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" class="alert alert-success system-alert"><i class="bi bi-check-circle"></i>{{ message }}</div>
    <div v-if="error" class="alert alert-danger system-alert">
      <i class="bi bi-exclamation-triangle"></i>{{ error }}
    </div>
    <div v-if="loading" class="app-card system-loading">
      <span class="spinner-border spinner-border-sm"></span> Đang tải cài đặt...
    </div>

    <div v-else class="settings-layout">
      <section v-for="group in settingGroups" :key="group.category" class="app-card settings-group">
        <header>
          <div class="settings-group-icon"><i :class="['bi', categoryMeta(group.category).icon]"></i></div>
          <div>
            <span class="system-kicker">{{ group.category }}</span>
            <h2>{{ categoryMeta(group.category).name }}</h2>
            <p>{{ categoryMeta(group.category).description }}</p>
          </div>
        </header>
        <div class="settings-grid">
          <label
            v-for="setting in group.items"
            :key="setting.systemSettingId"
            :class="['setting-field', { 'is-boolean': setting.dataType === 'BOOLEAN' }]"
          >
            <template v-if="setting.dataType === 'BOOLEAN'">
              <span
                ><strong>{{ setting.settingName }}</strong
                ><small>{{ setting.description }}</small></span
              >
              <input v-model="setting.booleanValue" class="form-check-input" type="checkbox" />
            </template>
            <template v-else>
              <span
                ><strong>{{ setting.settingName }}</strong
                ><small>{{ setting.description }}</small></span
              >
              <div class="setting-input-wrap">
                <i :class="['bi', dataTypeIcon(setting.dataType)]"></i
                ><input
                  v-model="setting.settingValue"
                  :type="inputType(setting.dataType)"
                  class="form-control"
                  :min="setting.dataType === 'NUMBER' ? 0 : undefined"
                />
              </div>
            </template>
          </label>
        </div>
      </section>
      <div class="settings-note">
        <i class="bi bi-info-circle"></i
        ><span
          ><strong>Dữ liệu được lưu trực tiếp vào SQL Server.</strong> Mỗi cấu hình đều có mô tả, kiểu dữ liệu và tài
          khoản cập nhật gần nhất.</span
        >
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import systemAdministrationService from '../../services/systemAdministrationService'

defineOptions({ name: 'SystemSettingsView' })

const settings = ref([])
const loading = ref(false)
const saving = ref(false)
const message = ref('')
const error = ref('')
const settingGroups = computed(() =>
  Object.entries(Object.groupBy(settings.value, (item) => item.category)).map(([category, items]) => ({
    category,
    items
  }))
)

onMounted(loadSettings)

async function loadSettings() {
  loading.value = true
  error.value = ''
  try {
    const result = await systemAdministrationService.getSettings()
    settings.value = result.map((item) => ({
      ...item,
      booleanValue: String(item.settingValue).toLowerCase() === 'true'
    }))
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    loading.value = false
  }
}

async function saveSettings() {
  saving.value = true
  error.value = ''
  message.value = ''
  try {
    const items = settings.value.map((item) => ({
      settingKey: item.settingKey,
      settingValue: item.dataType === 'BOOLEAN' ? String(item.booleanValue) : String(item.settingValue ?? '')
    }))
    await systemAdministrationService.saveSettings(items)
    message.value = 'Đã lưu cài đặt hệ thống.'
    await loadSettings()
  } catch (requestError) {
    error.value = requestError.message
  } finally {
    saving.value = false
  }
}

function categoryMeta(category) {
  return (
    {
      GENERAL: {
        name: 'Thông tin chung',
        description: 'Tên hệ thống, đơn vị vận hành và kênh hỗ trợ.',
        icon: 'bi-building'
      },
      LEARNING: {
        name: 'Quy tắc học tập',
        description: 'Giá trị mặc định áp dụng khi tạo nội dung đào tạo.',
        icon: 'bi-mortarboard'
      },
      SECURITY: {
        name: 'Bảo mật và vận hành',
        description: 'Kiểm soát phiên đăng nhập và trạng thái bảo trì.',
        icon: 'bi-shield-lock'
      }
    }[category] || { name: category, description: 'Cấu hình hệ thống.', icon: 'bi-sliders' }
  )
}
function inputType(dataType) {
  return { NUMBER: 'number', EMAIL: 'email', URL: 'url' }[dataType] || 'text'
}
function dataTypeIcon(dataType) {
  return { NUMBER: 'bi-123', EMAIL: 'bi-envelope', URL: 'bi-link-45deg' }[dataType] || 'bi-fonts'
}
</script>

<style scoped src="../../assets/css/pages/cms/system-management.css"></style>
