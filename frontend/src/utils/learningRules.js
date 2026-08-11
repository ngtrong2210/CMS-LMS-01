export function formatInteractionTime(seconds) {
  const safe = Math.max(0, Math.floor(Number(seconds) || 0))
  return `${String(Math.floor(safe / 60)).padStart(2, '0')}:${String(safe % 60).padStart(2, '0')}`
}

export function isSingleChoiceCorrect(selectedIndex, correctIndex) {
  return Number.isInteger(selectedIndex) && selectedIndex === correctIndex
}

export function shouldTriggerInteraction(previousTime, currentTime, interactionTime, answered = false) {
  if (answered) return false
  const previous = Math.max(0, Number(previousTime) || 0)
  const current = Math.max(previous, Number(currentTime) || 0)
  const marker = Math.max(0, Number(interactionTime) || 0)
  return previous < marker && current >= marker
}

export function calculateCourseProgress(completedLessons, totalRequiredLessons) {
  if (totalRequiredLessons <= 0) return 0
  return Math.min(100, Math.max(0, Math.round((completedLessons / totalRequiredLessons) * 10000) / 100))
}

export function canCompleteLesson({ watchPercent, requiredWatchPercent, score, passingScore, requiredQuestionsAnswered }) {
  return Number(watchPercent) >= Number(requiredWatchPercent)
    && Number(score) >= Number(passingScore)
    && Boolean(requiredQuestionsAnswered)
}
