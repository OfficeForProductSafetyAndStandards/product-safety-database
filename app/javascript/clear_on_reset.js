'use strict'

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-opss-clear-on-reset="trigger"]').forEach(triggerElement => {
    triggerElement.addEventListener('click', (e) => {
      e.preventDefault()
      document.querySelectorAll('[type="search"][data-opss-clear-on-reset="element"]').forEach(el => {
        el.value = null // Clear all search fields
      })
      document.querySelectorAll('[data-opss-clear-on-reset="element"] :checked').forEach(el => {
        el.selected = false // Clear all <select> elements
        el.checked = false // Clear all checkboxes
      })
      document.querySelectorAll('[data-opss-reset-to-default="element"]').forEach(el => {
        el.querySelector('input[type="radio"]').checked = true // Reset all radio buttons to the first option
      })
      document.querySelectorAll('.govuk-radios__conditional').forEach(el => {
        el.classList.add('govuk-radios__conditional--hidden') // Hide all conditional radio buttons
      })
      document.querySelectorAll('[data-opss-clear-on-reset="autocomplete"]').forEach(el => {
        el.querySelector(':checked').selected = false // Clear the <select> element
        el.parentElement.querySelector('input.autocomplete__input').value = null // Clear the text box
      })
      return false
    }, false)
  })
}, false)
