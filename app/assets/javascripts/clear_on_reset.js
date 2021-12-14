import $ from 'jquery'

$(document).ready(() => {
  $('[data-opss-clear-on-reset="trigger"]').click((e) => {
    e.preventDefault()
    $('[data-opss-clear-on-reset="element"]').val(null)
    $('[data-opss-clear-on-reset="element"]').find(':selected').prop('selected', "all")
    $('[data-opss-clear-on-reset="element"]').find(':checked').prop('checked', false)
    $('[data-opss-reset-to-default="element"]').find(':radio[checked]').prop('checked', true)
    $('.govuk-radios__conditional').addClass("govuk-radios__conditional--hidden")
    $('[data-opss-clear-on-reset="autocomplete"]').find(':selected').prop('selected', false)
    $('[data-opss-clear-on-reset="autocomplete"]').each((idx, ele) => {
      $(ele).parent().find('input.autocomplete__input').val(null)
    })
    return false
  })
})
