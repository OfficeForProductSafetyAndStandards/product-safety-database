import $ from 'jquery'

$(document).ready(() => {
  $('#cases-search-form #sort-by-fieldset #sort_by').change(() => {
    $('#cases-search-form').submit()
  })
})
