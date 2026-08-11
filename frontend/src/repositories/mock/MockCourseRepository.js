import database from '../../services/MockDatabaseService'
export default {
  async getList(params={}) { const q=(params.search||'').toLowerCase(); const items=database.get('courses').filter(x=>!q || `${x.title} ${x.code}`.toLowerCase().includes(q)); return {items,page:1,pageSize:20,totalItems:items.length,totalPages:1} },
  async getById(id) { return database.find('courses', item=>item.id===Number(id)) },
  async create(data) { return database.insert('courses',data) },
  async update(id,data) { return database.update('courses',id,data) },
  async delete(id) { database.delete('courses',id) },
}
