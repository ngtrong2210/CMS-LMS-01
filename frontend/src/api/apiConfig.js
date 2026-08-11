export const apiConfig = {
  baseURL: import.meta.env.VITE_API_URL || 'https://localhost:7001/api',
  dataMode: import.meta.env.VITE_DATA_MODE || 'mock',
  timeout: 15000,
}

export function resolveApiAssetUrl(relativeUrl) {
  if (!relativeUrl) return ''
  if (/^https?:\/\//i.test(relativeUrl)) return relativeUrl
  const apiOrigin = apiConfig.baseURL.replace(/\/api\/?$/i, '')
  return `${apiOrigin}${relativeUrl.startsWith('/') ? '' : '/'}${relativeUrl}`
}
