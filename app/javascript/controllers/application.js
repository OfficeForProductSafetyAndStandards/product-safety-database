'use strict'

import { Application } from '@hotwired/stimulus'
import NestedForm from 'stimulus-rails-nested-form'
import Clipboard from 'stimulus-clipboard'
import VisibilityController from './visibility_controller'

const application = Application.start()

application.register('nested-form', NestedForm)
application.register('clipboard', Clipboard)
application.register('visibility', VisibilityController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
