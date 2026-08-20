import { describe, expect, it } from 'vitest'
import { canonicalYouTubeUrl, extractYouTubeVideoId } from './videoSources'

describe('videoSources', () => {
  it.each([
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtu.be/dQw4w9WgXcQ',
    'https://www.youtube.com/shorts/dQw4w9WgXcQ',
    'https://www.youtube.com/embed/dQw4w9WgXcQ'
  ])('extracts a YouTube id from %s', (url) => expect(extractYouTubeVideoId(url)).toBe('dQw4w9WgXcQ'))

  it('rejects non YouTube links', () => expect(extractYouTubeVideoId('https://example.com/video')).toBe(''))
  it('returns a canonical watch URL', () =>
    expect(canonicalYouTubeUrl('https://youtu.be/dQw4w9WgXcQ')).toBe('https://www.youtube.com/watch?v=dQw4w9WgXcQ'))
})
