import { apiConfig } from '../api/apiConfig'
import mockRepository from '../repositories/mock/MockCourseRepository'
import apiRepository from '../repositories/api/ApiCourseRepository'
const repository = apiConfig.dataMode === 'api' ? apiRepository : mockRepository
export default { getCourses:params=>repository.getList(params), getCourse:id=>repository.getById(id), createCourse:data=>repository.create(data), updateCourse:(id,data)=>repository.update(id,data), deleteCourse:id=>repository.delete(id) }
