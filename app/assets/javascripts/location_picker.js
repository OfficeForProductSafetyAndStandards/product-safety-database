import $ from 'jquery'
import openregisterLocationPicker from 'govuk-country-and-territory-autocomplete'

import locationGraph from 'govuk-country-and-territory-autocomplete/dist/location-autocomplete-graph.json'

// TODO progressive enhancement for https://github.com/alphagov/govuk-country-and-territory-autocomplete

$(document).ready(() => {
  const autocompleteElement = document.getElementById('location-autocomplete')
  if (autocompleteElement) {
    openregisterLocationPicker({
      selectElement: autocompleteElement,
      url: locationGraph
    })
  }
})

$(document).ready(() => {
  const autocompleteElement = document.getElementById('notifying-country-autocomplete')
  if (autocompleteElement) {
    openregisterLocationPicker({
      additionalEntries: [
        { name: 'England', code: 'country:ENG' },
        { name: 'Scotland', code: 'country:SCO' },
        { name: 'Wales', code: 'country:WAL' },
        { name: 'Northern Ireland', code: 'country:NIL' }
      ],
      additionalSynonyms: [
        { name: 'England', code: 'country:ENG' },
        { name: 'Scotland', code: 'country:SCO' },
        { name: 'Wales', code: 'country:WAL' },
        { name: 'Northern Ireland', code: 'country:NIL' }
      ],
      selectElement: autocompleteElement,
      url: locationGraph
    })
  }
})
