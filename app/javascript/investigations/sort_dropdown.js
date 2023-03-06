'use strict'

document.addEventListener('DOMContentLoaded', () => {
  const sortInput = document.querySelector('#sort-by-fieldset #sort_by')

  if (sortInput) {
    sortInput.addEventListener('change', (e) => {
      e.preventDefault()
      window.location.assign(e.target.querySelector(':checked').dataset.url)
      return false
    })
  }
})
