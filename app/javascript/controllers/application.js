'use strict'

import { Application } from '@hotwired/stimulus'
import NestedForm from 'stimulus-rails-nested-form'

const application = Application.start()

application.register('nested-form', NestedForm)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
