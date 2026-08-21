import api from '../api/axiosClient'

export default {
  getUsers: (params) => api.get('/cms/system/users', { params }),
  getUser: (userId) => api.get(`/cms/system/users/${userId}`),
  createUser: (data) => api.post('/cms/system/users', data),
  updateUser: (userId, data) => api.put(`/cms/system/users/${userId}`, data),
  setUserStatus: (userId, status) => api.patch(`/cms/system/users/${userId}/status`, { status }),
  getRoles: () => api.get('/cms/system/roles'),
  getRolePermissions: (roleId) => api.get(`/cms/system/roles/${roleId}/permissions`),
  saveRolePermissions: (roleId, permissionCodes) =>
    api.put(`/cms/system/roles/${roleId}/permissions`, { permissionCodes }),
  getSettings: () => api.get('/cms/system/settings'),
  saveSettings: (items) => api.put('/cms/system/settings', { items })
}
