'use strict'

function mutuallyExclusive (el) {
  const checkboxes = Array.from(el.querySelectorAll('.js-mutually-exclusive__item[data-mutually-exclusive-set-id]'))
  const checkboxesGroupedBySetId = checkboxes.reduce((acc, checkbox) => {
    const setId = checkbox.dataset.mutuallyExclusiveSetId
    acc[setId] = acc[setId] || []
    acc[setId].push(checkbox)
    return acc
  }, {})

  el.addEventListener('click', event => {
    if (event.target.classList.contains('js-mutually-exclusive__item') && event.target.checked) {
      const setsToUnCheck = Object.keys(checkboxesGroupedBySetId).filter(setId => setId !== event.target.dataset.mutuallyExclusiveSetId)
      setsToUnCheck.forEach(unCheckSet)
    }
  })

  const unCheckSet = setId => checkboxesGroupedBySetId[setId].forEach(unCheck)

  const unCheck = checkbox => {
    if (checkbox.checked) {
      checkbox.click()
      checkbox.checked = false
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.js-mutually-exclusive').forEach(el => {
    mutuallyExclusive(el)
  })
})
