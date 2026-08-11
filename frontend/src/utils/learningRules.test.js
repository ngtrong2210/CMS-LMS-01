import { describe, expect, it } from 'vitest'
import { calculateCourseProgress, canCompleteLesson, formatInteractionTime, isSingleChoiceCorrect, shouldTriggerInteraction } from './learningRules'

describe('learning rules', () => {
  it('triggers an unanswered interaction only when the playback crosses its timestamp', () => {
    expect(shouldTriggerInteraction(19.8, 20.1, 20)).toBe(true)
    expect(shouldTriggerInteraction(20.1, 21, 20)).toBe(false)
    expect(shouldTriggerInteraction(19, 21, 20, true)).toBe(false)
  })

  it('calculates stable and bounded course progress', () => {
    expect(calculateCourseProgress(6, 15)).toBe(40)
    expect(calculateCourseProgress(20, 15)).toBe(100)
    expect(calculateCourseProgress(0, 0)).toBe(0)
  })

  it('requires watch, score and required interactions before completing a lesson', () => {
    expect(canCompleteLesson({ watchPercent: 80, requiredWatchPercent: 80, score: 10, passingScore: 10, requiredQuestionsAnswered: true })).toBe(true)
    expect(canCompleteLesson({ watchPercent: 79.99, requiredWatchPercent: 80, score: 10, passingScore: 10, requiredQuestionsAnswered: true })).toBe(false)
    expect(canCompleteLesson({ watchPercent: 100, requiredWatchPercent: 80, score: 10, passingScore: 10, requiredQuestionsAnswered: false })).toBe(false)
  })

  it('formats marker time and evaluates the selected choice', () => {
    expect(formatInteractionTime(65)).toBe('01:05')
    expect(isSingleChoiceCorrect(1, 1)).toBe(true)
    expect(isSingleChoiceCorrect(0, 1)).toBe(false)
  })
})
