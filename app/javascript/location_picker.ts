import accessibleAutocomplete from 'accessible-autocomplete'

document.addEventListener('DOMContentLoaded', () => {
  enhanceCountryAutocomplete('location-autocomplete')
  enhanceCountryAutocomplete('notifying-country-autocomplete')
})

function enhanceCountryAutocomplete(elementId: string): void {
  const autocompleteElement = document.getElementById(elementId)
  if (!autocompleteElement) return

  accessibleAutocomplete.enhanceSelectElement({
    selectElement: autocompleteElement
  })
}
