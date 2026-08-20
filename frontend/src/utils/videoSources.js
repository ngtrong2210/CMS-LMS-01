export const VIDEO_SOURCE_LOCAL = 'LOCAL'
export const VIDEO_SOURCE_YOUTUBE = 'YOUTUBE'

export function normalizeVideoSource(value) {
  return String(value || VIDEO_SOURCE_LOCAL).toUpperCase() === VIDEO_SOURCE_YOUTUBE
    ? VIDEO_SOURCE_YOUTUBE
    : VIDEO_SOURCE_LOCAL
}

export function extractYouTubeVideoId(value) {
  try {
    const url = new URL(String(value || '').trim())
    if (url.protocol !== 'https:') return ''
    const host = url.hostname.toLowerCase().replace(/^www\./, '')
    let id = ''
    if (host === 'youtu.be') id = url.pathname.split('/').filter(Boolean)[0] || ''
    else if (host === 'youtube.com' || host.endsWith('.youtube.com') || host === 'youtube-nocookie.com') {
      if (url.pathname === '/watch') id = url.searchParams.get('v') || ''
      else if (/^\/(embed|shorts|live)\//.test(url.pathname)) id = url.pathname.split('/')[2] || ''
    }
    return /^[A-Za-z0-9_-]{11}$/.test(id) ? id : ''
  } catch {
    return ''
  }
}

export function canonicalYouTubeUrl(value) {
  const id = extractYouTubeVideoId(value)
  return id ? `https://www.youtube.com/watch?v=${id}` : ''
}

export function youtubeThumbnailUrl(value) {
  const id = extractYouTubeVideoId(value)
  return id ? `https://i.ytimg.com/vi/${id}/hqdefault.jpg` : ''
}

export function isYouTubeSource(value) {
  return normalizeVideoSource(value) === VIDEO_SOURCE_YOUTUBE
}
