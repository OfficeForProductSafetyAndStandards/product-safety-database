import $ from 'jquery'

function mutuallyExclusive(el) {
  const checkboxes = Array.from(this.querySelectorAll('.js-mutually-exclusive__item[data-mutually-exclusive-set-id]'))
  this.checkboxesGroupedBySetId = checkboxes.reduce((acc, checkbox) => {
    const setId = checkbox.dataset.mutuallyExclusiveSetId
    acc[setId] = acc[setId] || []
    acc[setId].push(checkbox)
    return acc;
  }, {})

  const unCheck = checkbox => {
    if(checkbox.checked) {
      checkbox.click()
      checkbox.checked = false
         }
  }
  const unCheckSet = setId => this.checkboxesGroupedBySetId[setId].forEach(unCheck)

  this.addEventListener("click", event => {
    if (event.target.classList.contains("js-mutually-exclusive__item") && event.target.checked) {
      const setsToUnCheck = Object.keys(this.checkboxesGroupedBySetId).filter(setId => setId !== event.target.dataset.mutuallyExclusiveSetId)
      setsToUnCheck.forEach(unCheckSet)
    }
  })
}

$(document).ready(() => {
  const mutuallyExclusiveComponents = document.getElementsByClassName('js-mutually-exclusive');
  for(let mutuallyExclusiveComponent of mutuallyExclusiveComponents) {
    mutuallyExclusive.call(mutuallyExclusiveComponent)
  }
})
