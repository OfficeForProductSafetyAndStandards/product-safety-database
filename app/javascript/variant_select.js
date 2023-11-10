'use strict'

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.opss-variant-select-button').forEach(el => {
    el.addEventListener('click', event => {
      const selector = '#variant-select-' + event.target.dataset.identifier + '-' + event.target.dataset.variant
      event.preventDefault()

      // Reset existing panel selections for the chosen identifier
      document.querySelectorAll('[id^="variant-select-' + event.target.dataset.identifier + '-"]').forEach(el => {
        el.classList.remove('opss-variant-select-panel--selected')
      })

      // Select the relevant panel for the chosen identifier and variant
      document.querySelector(selector + '-panel').classList.add('opss-variant-select-panel--selected')

      // Select the relevant form element for the chosen identifier and variant
      document.querySelector(selector + '-form').checked = true
    })
  })

  document.querySelectorAll('.opss-variant-select-form input[type="radio"]').forEach(el => {
    el.addEventListener('change', event => {
      const selector = '#' + event.target.id.replace('-form', '')
      const identifier = selector.replace('#variant-select-', '').split('-')[0]

      // Reset existing panel selections for the chosen identifier
      document.querySelectorAll('[id^="variant-select-' + identifier + '-"]').forEach(el => {
        el.classList.remove('opss-variant-select-panel--selected')
      })

      // Select the relevant panel for the chosen identifier and variant
      document.querySelector(selector + '-panel').classList.add('opss-variant-select-panel--selected')
    })

    // Check for form elements that are already selected and select the relevant panels
    if (el.checked) {
      const selector = '#' + el.id.replace('-form', '')
      document.querySelector(selector + '-panel').classList.add('opss-variant-select-panel--selected')
    }
  })
})
