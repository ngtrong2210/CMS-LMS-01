import axios from 'axios'
import { apiConfig } from './apiConfig'
import { normalizeApiError } from './apiErrorHandler'

const axiosClient = axios.create({ baseURL: apiConfig.baseURL, timeout: apiConfig.timeout })
axiosClient.interceptors.request.use(config => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})
axiosClient.interceptors.response.use(response => response.data?.data ?? response.data, error => {
  if (error.response?.status === 401) {
    localStorage.removeItem('accessToken'); localStorage.removeItem('refreshToken'); localStorage.removeItem('lms_user')
    if (location.pathname !== '/login') location.assign('/login')
  }
  return Promise.reject(normalizeApiError(error))
})
export default axiosClient
