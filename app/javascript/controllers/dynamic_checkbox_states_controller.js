'use strict'

import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    this.update()
  }

  update () {
    // Get a list of all the checkboxes that need to be disabled by referencing all the checkboxes that are currently checked
    const targets = [].concat(...Array.from(this.element.querySelectorAll('input[type=checkbox]:checked')).map((el) => el.dataset.dynamicCheckboxStatesDisableTargets.split(',')))
    const uniqueTargets = new Set(targets)

    this.element.querySelectorAll('input[type=checkbox]').forEach((el) => {
      if (uniqueTargets.has(el.value)) {
        el.disabled = true
        el.checked = false
      } else {
        el.disabled = false
      }
    })
  }
}
