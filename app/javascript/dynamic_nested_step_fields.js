/* global MutationObserver */

'use strict'

import { i18n } from './i18n'

document.addEventListener('DOMContentLoaded', () => {
  const dynamicNestedStepFieldsCallback = () => {
    document.querySelectorAll('.nested-form-wrapper:not([style*="display: none;"])').forEach((el, i) => {
      // Update the step heading and hint depending on the current step
      const stepHint = el.querySelector('.opss-step-hint')
      const stepHintText = i18n.t(el.dataset.i18nScope + '.step_' + i + '_hint', { defaultValue: '' })
      el.querySelector('.opss-step-heading').innerText = 'Step ' + (i + 1)
      stepHint.innerText = stepHintText

      if (stepHintText === '') {
        stepHint.style.display = 'none'
      } else {
        stepHint.style.display = 'block'
      }
    })

    // Re-init GOV.UK Frontend to pick up new form fields
    window.GOVUKFrontend.initAll({ scope: document.querySelector('opss-harm-scenario-steps') })
  }

  // Detect added or removed steps
  const dynamicNestedStepFieldsNewObserver = new MutationObserver(dynamicNestedStepFieldsCallback)
  const dynamicNestedStepFieldsExistingObserver = new MutationObserver(dynamicNestedStepFieldsCallback)
  dynamicNestedStepFieldsNewObserver.observe(document.querySelector('form[data-controller="nested-form"]'), { childList: true })
  dynamicNestedStepFieldsExistingObserver.observe(document.querySelector('form[data-controller="nested-form"]'), { subtree: true, attributeFilter: ['style'] })
})
