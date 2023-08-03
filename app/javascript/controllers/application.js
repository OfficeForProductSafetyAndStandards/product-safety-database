'use strict'

import { Application } from '@hotwired/stimulus'
import NestedForm from 'stimulus-rails-nested-form'
import Clipboard from 'stimulus-clipboard'

const application = Application.start()

application.register('nested-form', NestedForm)
application.register('clipboard', Clipboard)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
