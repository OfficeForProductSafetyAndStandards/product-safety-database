'use strict'

// Replicates the behaviour of conditional radio buttons/checkboxes in the GOV.UK
// Design System for <select> elements which have an initial empty <option>
// to show/hide conditional elements based on whether the parent <select> element
// is empty.
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.govuk-select[aria-controls]').forEach(el => {
    // Sync the state of the conditional element based on the selected option
    const conditionalElement = el.ariaControlsElements[0]

    if (el.value === '') {
      conditionalElement.classList.add('opss-select__conditional--hidden')
      el.ariaExpanded = false
    } else {
      conditionalElement.classList.remove('opss-select__conditional--hidden')
      el.ariaExpanded = true
    }

    // Add listener to show/hide the conditional element based on the selected option
    el.addEventListener('change', event => {
      const conditionalElement = event.target.ariaControlsElements[0]

      if (event.target.value === '') {
        conditionalElement.classList.add('opss-select__conditional--hidden')
        el.ariaExpanded = false
      } else {
        conditionalElement.classList.remove('opss-select__conditional--hidden')
        el.ariaExpanded = true
      }
    })
  })
})
