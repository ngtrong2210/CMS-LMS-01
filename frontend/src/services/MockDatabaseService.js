import users from '../mock/users.json'
import courses from '../mock/courses.json'
import chapters from '../mock/chapters.json'
import lessons from '../mock/lessons.json'
import videos from '../mock/videos.json'
import questions from '../mock/questions.json'
import questionOptions from '../mock/questionOptions.json'
import videoInteractions from '../mock/videoInteractions.json'
import enrollments from '../mock/enrollments.json'
import studentProgress from '../mock/studentProgress.json'
import studentAnswers from '../mock/studentAnswers.json'
import learningSessions from '../mock/learningSessions.json'
import roles from '../mock/roles.json'

const STORAGE_KEY = 'learnhub_mock_database_v1'
const seed = { users, roles, courses, chapters, lessons, videos, questions, questionOptions, videoInteractions, enrollments, studentProgress, studentAnswers, learningSessions }

class MockDatabaseService {
  initialize() { if (!localStorage.getItem(STORAGE_KEY)) this.reset(); return this.getDatabase() }
  reset() { localStorage.setItem(STORAGE_KEY, JSON.stringify(seed)); return this.getDatabase() }
  getDatabase() { return JSON.parse(localStorage.getItem(STORAGE_KEY) || JSON.stringify(seed)) }
  save(db) { localStorage.setItem(STORAGE_KEY, JSON.stringify(db)) }
  get(table) { return this.getDatabase()[table] || [] }
  find(table, predicate) { return this.get(table).find(predicate) }
  insert(table, value) { const db=this.getDatabase(); const item={...value,id:value.id || Date.now()}; db[table]=[...(db[table]||[]),item]; this.save(db); return item }
  update(table, id, value) { const db=this.getDatabase(); const index=db[table].findIndex(item=>item.id===Number(id)); if(index<0) throw new Error('Không tìm thấy dữ liệu.'); db[table][index]={...db[table][index],...value,id:Number(id)}; this.save(db); return db[table][index] }
  delete(table, id) { const db=this.getDatabase(); db[table]=db[table].filter(item=>item.id!==Number(id)); this.save(db) }
}
export default new MockDatabaseService()
