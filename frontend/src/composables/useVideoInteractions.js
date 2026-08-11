const valueOf = (source, ...names) => names.map(name => source?.[name]).find(value => value !== undefined && value !== null)

export function normalizeInteraction(row, index = 0) {
  const id = Number(valueOf(row, 'id', 'Id'))
  const timeSeconds = Number(valueOf(row, 'timeSeconds', 'TimeSeconds', 'time'))
  if (!Number.isFinite(id) || id <= 0 || !Number.isFinite(timeSeconds) || timeSeconds < 0) {
    if (import.meta.env?.DEV) console.warn('[InteractiveVideo] Bỏ qua tương tác không hợp lệ.', row)
    return null
  }
  const rawOptions = valueOf(row, 'options', 'Options')
  let options = []
  try { options = typeof rawOptions === 'string' ? JSON.parse(rawOptions) : rawOptions || [] } catch { options = [] }
  return {
    ...row,
    id,
    questionId: Number(valueOf(row, 'questionId', 'QuestionId')),
    timeSeconds,
    label: valueOf(row, 'label', 'QuestionText', 'questionText') || 'Câu hỏi',
    description: valueOf(row, 'description', 'Description') || '',
    type: valueOf(row, 'type', 'QuestionType', 'questionType') || 'SINGLE_CHOICE',
    required: Boolean(valueOf(row, 'required', 'Required')),
    pauseVideo: Boolean(valueOf(row, 'pauseVideo', 'PauseVideo')),
    allowSkip: Boolean(valueOf(row, 'allowSkip', 'AllowSkip')),
    score: Number(valueOf(row, 'score', 'Score') || 0),
    attemptLimit: Number(valueOf(row, 'attemptLimit', 'AttemptLimit') || 1),
    sortOrder: Number(valueOf(row, 'sortOrder', 'SortOrder') || index + 1),
    answered: Boolean(valueOf(row, 'answered', 'Answered')),
    attempts: Number(valueOf(row, 'attempts', 'AttemptNumber') || 0),
    options: options.map(option => ({
      code: valueOf(option, 'code', 'OptionCode', 'optionCode'),
      text: valueOf(option, 'text', 'OptionText', 'optionText')
    }))
  }
}

export function normalizeInteractions(rows = []) {
  return rows.map(normalizeInteraction).filter(Boolean).sort((a, b) => a.timeSeconds - b.timeSeconds || a.sortOrder - b.sortOrder || a.id - b.id)
}

export function createInteractionEngine(rows = [], answeredIds = []) {
  let interactions = normalizeInteractions(rows)
  let previousTime = 0
  let started = false
  let seeking = false
  let active = null
  let queue = []
  const triggered = new Set(answeredIds.map(Number))

  const dequeue = () => {
    active = queue.shift() || null
    if (active) triggered.add(active.id)
    return active
  }
  return {
    get interactions() { return interactions },
    get active() { return active },
    get pendingCount() { return queue.length },
    get previousTime() { return previousTime },
    get triggeredIds() { return [...triggered] },
    reset(nextRows = interactions, nextAnsweredIds = []) {
      interactions = normalizeInteractions(nextRows)
      previousTime = 0; started = false; seeking = false; active = null; queue = []
      triggered.clear(); nextAnsweredIds.map(Number).forEach(id => triggered.add(id))
    },
    loadAt(time) { previousTime = Math.max(0, Number(time) || 0); started = previousTime > 0 },
    start(currentTime = 0) {
      if (active || started || Number(currentTime) > 0) return null
      started = true
      queue = interactions.filter(item => item.timeSeconds === 0 && !item.answered && !triggered.has(item.id))
      return dequeue()
    },
    tick(currentTime) {
      const current = Math.max(0, Number(currentTime) || 0)
      if (seeking) return null
      if (active) { previousTime = current; return null }
      const crossed = interactions.filter(item => !item.answered && !triggered.has(item.id) && previousTime < item.timeSeconds && item.timeSeconds <= current)
      previousTime = current
      if (!crossed.length) return null
      queue = crossed
      return dequeue()
    },
    beginSeek() { seeking = true },
    endSeek(currentTime) { previousTime = Math.max(0, Number(currentTime) || 0); started = true; seeking = false },
    open(interaction) {
      const item = normalizeInteraction(interaction)
      if (!item || active || (item.answered && item.attempts >= item.attemptLimit)) return null
      queue = []; active = item; triggered.add(item.id); return active
    },
    close(force = false) {
      if (active?.required && !force) return false
      active = null; queue = []; return true
    },
    continue() { active = null; return dequeue() }
  }
}
