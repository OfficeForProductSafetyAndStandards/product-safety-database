import $ from 'jquery'

$(document).ready(() => {
  $("#cases-search-form #results-sort").change(() => {
    $("#cases-search-form").submit()
  })
})
