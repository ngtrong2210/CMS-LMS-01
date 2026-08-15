const searchInput = document.querySelector('#globalSearch')
const searchCount = document.querySelector('#searchCount')
const searchableItems = [...document.querySelectorAll('[data-search]')]
const entityButtons = [...document.querySelectorAll('.entity')]
const erdCanvas = document.querySelector('#erdCanvas')
let zoomLevel = 1

function normalize(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
}

function applySearch() {
  const term = normalize(searchInput.value.trim())
  let visible = 0

  searchableItems.forEach((item) => {
    const matched = !term || normalize(`${item.dataset.search} ${item.textContent}`).includes(term)
    item.classList.toggle('hidden', !matched)
    if (matched) visible += 1
  })

  searchCount.textContent = term ? `${visible} mục phù hợp` : `${searchableItems.length} mục tra cứu`
}

searchInput.addEventListener('input', applySearch)

document.querySelectorAll('.tab-button').forEach((button) => {
  button.addEventListener('click', () => {
    const group = button.closest('[data-tabs]')
    group.querySelectorAll('.tab-button').forEach((item) => item.classList.remove('active'))
    group.querySelectorAll('.tab-panel').forEach((item) => item.classList.remove('active'))
    button.classList.add('active')
    group.querySelector(`#${button.dataset.tab}`).classList.add('active')
  })
})

entityButtons.forEach((button) => {
  button.addEventListener('click', () => {
    entityButtons.forEach((item) => item.classList.remove('focused'))
    button.classList.add('focused')
    searchInput.value = button.dataset.table
    applySearch()
    document.querySelector('#tableDictionary').scrollIntoView({ behavior: 'smooth', block: 'start' })
  })
})

document.querySelectorAll('[data-zoom]').forEach((button) => {
  button.addEventListener('click', () => {
    const action = button.dataset.zoom
    zoomLevel = action === 'reset' ? 1 : Math.min(1.35, Math.max(0.7, zoomLevel + (action === 'in' ? 0.1 : -0.1)))
    erdCanvas.style.zoom = zoomLevel
    document.querySelector('#zoomValue').textContent = `${Math.round(zoomLevel * 100)}%`
  })
})

const sectionObserver = new IntersectionObserver(
  (entries) => {
    const active = entries.filter((entry) => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0]
    if (!active) return
    document.querySelectorAll('.nav-link').forEach((link) => link.classList.toggle('active', link.hash === `#${active.target.id}`))
  },
  { rootMargin: '-20% 0px -65% 0px', threshold: [0.05, 0.3] }
)

document.querySelectorAll('main section[id], .hero[id]').forEach((section) => sectionObserver.observe(section))
applySearch()
