export const apiConfig = {
  baseURL: import.meta.env.VITE_API_URL || 'https://localhost:7001/api',
  dataMode: import.meta.env.VITE_DATA_MODE || 'mock',
  timeout: 15000,
}
