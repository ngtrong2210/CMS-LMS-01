export const apiConfig = {
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:7001/api',
  dataMode: import.meta.env.VITE_DATA_MODE || 'api',
  timeout: 15000,
}

export function resolveApiAssetUrl(relativeUrl) {
  if (!relativeUrl) return ''
  if (/^https?:\/\//i.test(relativeUrl)) return relativeUrl
  const apiOrigin = apiConfig.baseURL.replace(/\/api\/?$/i, '')
  return `${apiOrigin}${relativeUrl.startsWith('/') ? '' : '/'}${relativeUrl}`
}
