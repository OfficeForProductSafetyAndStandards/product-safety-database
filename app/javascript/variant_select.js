'use strict'

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.opss-variant-select-button').forEach(el => {
    el.addEventListener('click', event => {
      event.preventDefault()

      // Reset existing panel selections for the chosen identifier
      document.querySelectorAll('[data-type="panel"][data-identifier="' + event.target.dataset.identifier + '"]').forEach(el => {
        el.classList.remove('opss-variant-select-panel--selected')
      })

      // Select the relevant panel for the chosen identifier and variant
      document.querySelector('[data-type="panel"][data-identifier="' + event.target.dataset.identifier + '"][data-variant="' + event.target.dataset.variant + '"]').classList.add('opss-variant-select-panel--selected')

      // Select the relevant form element for the chosen identifier and variant
      document.querySelector('[data-type="form"][data-identifier="' + event.target.dataset.identifier + '"][data-variant="' + event.target.dataset.variant + '"]').checked = true
    })
  })

  document.querySelectorAll('.opss-variant-select-form input[type="radio"]').forEach(el => {
    el.addEventListener('change', event => {
      // Reset existing panel selections for the chosen identifier
      document.querySelectorAll('[data-type="panel"][data-identifier="' + event.target.dataset.identifier + '"]').forEach(el => {
        el.classList.remove('opss-variant-select-panel--selected')
      })

      // Select the relevant panel for the chosen identifier and variant
      document.querySelector('[data-type="panel"][data-identifier="' + event.target.dataset.identifier + '"][data-variant="' + event.target.dataset.variant + '"]').classList.add('opss-variant-select-panel--selected')
    })

    // Check for form elements that are already selected and select the relevant panels
    if (el.checked) {
      document.querySelector('[data-type="panel"][data-identifier="' + el.dataset.identifier + '"][data-variant="' + el.dataset.variant + '"]').classList.add('opss-variant-select-panel--selected')
    }
  })
})
