'use strict'

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('#which-businesses-page')) {
    const normalElements = [
      document.querySelector('#businesses_retailer'),
      document.querySelector('#businesses_distributor'),
      document.querySelector('#businesses_importer'),
      document.querySelector('#businesses_fulfillment_house'),
      document.querySelector('#businesses_manufacturer'),
      document.querySelector('#businesses_exporter')
    ]
    const elementOther = document.querySelector('#businesses_other')
    const elementNone = document.querySelector('#businesses_none')

    const deselectOthers = () => {
      normalElements.forEach((element) => {
        element.checked = false // eslint-disable-line no-param-reassign
      })
      if (elementOther.checked) {
        // This element must be clicked because it is responsible for showing and hiding a text box,
        // which doesn't happen if the checked property is manually set to true
        elementOther.click()
        elementNone.checked = true
      }
    }

    const deselectNone = () => {
      elementNone.checked = false
    }

    elementNone.addEventListener('input', deselectOthers)

    normalElements.forEach((element) => {
      element.addEventListener('input', deselectNone)
    })

    elementOther.addEventListener('input', deselectNone)
  }
})
