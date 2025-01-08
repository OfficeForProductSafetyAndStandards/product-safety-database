/* global MutationObserver */

'use strict'

import { initAll } from 'govuk-frontend'

document.addEventListener('DOMContentLoaded', () => {
  const dynamicNestedStepFieldsCallback = () => {
    document.querySelectorAll('.nested-form-wrapper:not([style*="display: none;"])').forEach((el, i) => {
      // Update the step heading depending on the current step
      el.querySelector('.opss-step-heading').innerText = 'Step ' + (i + 1)

      // Update added fields to use the correct child index
      if (el.innerHTML.indexOf('-new-record-') !== -1) {
        el.innerHTML = el.innerHTML.replace(/-new-record-/g, '-' + el.dataset.index + '-')
      }
    })

    // Re-init GOV.UK Frontend to pick up new form fields
    initAll({ scope: document.querySelector('opss-steps') })
  }

  // Detect added or removed steps
  if (document.querySelector('form[data-controller="nested-form"]')) {
    const dynamicNestedStepFieldsNewObserver = new MutationObserver(dynamicNestedStepFieldsCallback)
    const dynamicNestedStepFieldsExistingObserver = new MutationObserver(dynamicNestedStepFieldsCallback)
    dynamicNestedStepFieldsNewObserver.observe(document.querySelector('form[data-controller="nested-form"]'), { childList: true })
    dynamicNestedStepFieldsExistingObserver.observe(document.querySelector('form[data-controller="nested-form"]'), { subtree: true, attributeFilter: ['style'] })
  }
})
