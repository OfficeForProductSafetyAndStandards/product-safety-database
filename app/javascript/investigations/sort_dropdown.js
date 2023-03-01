import $ from 'jquery'

$(document).ready(() => {
  $('#sort-by-fieldset #sort_by').change((e) => {
    e.preventDefault()
    window.location.assign($(e.target).find(':selected').data('url'))
    return false
  })
})
