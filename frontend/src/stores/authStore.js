import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import authService from '../services/authService'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(JSON.parse(localStorage.getItem('lms_user') || 'null'))
  const isAuthenticated = computed(() => Boolean(user.value))
  const isStudent = computed(() => user.value?.role === 'STUDENT')
  const isAdmin = computed(() => user.value?.role === 'ADMIN')
  const isCmsUser = computed(() => ['ADMIN','TEACHER'].includes(user.value?.role))
  async function login(username, password) {
    const response = await authService.login(username, password)
    const { password: _, ...safeUser } = response.user
    user.value = safeUser
    localStorage.setItem('lms_user', JSON.stringify(safeUser))
    localStorage.setItem('accessToken', response.accessToken)
    if (response.refreshToken) localStorage.setItem('refreshToken', response.refreshToken)
    return safeUser
  }
  function logout() {
    user.value = null
    localStorage.removeItem('lms_user')
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
  }
  function hasPermission(permission) {
    return user.value?.permissions?.includes('*') || user.value?.permissions?.includes(permission)
  }
  return { user, isAuthenticated, isStudent, isAdmin, isCmsUser, login, logout, hasPermission }
})
