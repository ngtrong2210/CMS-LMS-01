import api from '../../api/axiosClient'
export default { getList:params=>api.get('/courses',{params}), getById:id=>api.get(`/courses/${id}`), getContent:id=>api.get(`/courses/${id}/content`), create:data=>api.post('/courses',data), update:(id,data)=>api.put(`/courses/${id}`,data), delete:id=>api.delete(`/courses/${id}`) }
