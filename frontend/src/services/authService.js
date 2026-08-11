import api from '../api/axiosClient'
import { apiConfig } from '../api/apiConfig'
import { demoUsers } from '../data/demo'
export default { async login(username,password){ if(apiConfig.dataMode==='api') return api.post('/auth/login',{username,password}); const user=demoUsers.find(x=>x.username===username&&x.password===password); if(!user) throw new Error('Tên đăng nhập hoặc mật khẩu không đúng'); return {accessToken:`mock.${btoa(username)}.token`,refreshToken:'mock-refresh-token',user} } }
