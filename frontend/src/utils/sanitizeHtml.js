const blockedTags = new Set(['SCRIPT', 'IFRAME', 'OBJECT', 'EMBED', 'FORM', 'META', 'LINK'])

export function sanitizeLearningHtml(value) {
  if (!value || typeof window === 'undefined') return value || ''
  const documentNode = new DOMParser().parseFromString(String(value), 'text/html')
  documentNode.body.querySelectorAll('*').forEach((element) => {
    if (blockedTags.has(element.tagName)) {
      element.remove()
      return
    }
    for (const attribute of [...element.attributes]) {
      const name = attribute.name.toLowerCase()
      const content = attribute.value.trim().toLowerCase()
      if (
        name.startsWith('on') ||
        name === 'srcdoc' ||
        ((name === 'href' || name === 'src') && content.startsWith('javascript:'))
      ) {
        element.removeAttribute(attribute.name)
      }
    }
  })
  return documentNode.body.innerHTML
}
