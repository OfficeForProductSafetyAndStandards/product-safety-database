'use strict'

import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['item', 'addLink']

  add (event) {
    event.preventDefault()

    const templateId = this.data.get('templateId')
    const template = document.getElementById(templateId)

    while (this.itemTarget.firstChild) {
      this.itemTarget.removeChild(this.itemTarget.firstChild)
    }

    this.itemTarget.appendChild(template.content.cloneNode(true))
    this.addLinkTarget.hidden = true
  }

  remove (event) {
    event.preventDefault()

    while (this.itemTarget.firstChild) {
      this.itemTarget.removeChild(this.itemTarget.firstChild)
    }

    this.addLinkTarget.hidden = false
  }
}
