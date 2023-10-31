'use strict'

import { Application } from '@hotwired/stimulus'
import NestedForm from 'stimulus-rails-nested-form'
import Clipboard from 'stimulus-clipboard'
import Reveal from 'stimulus-reveal-controller'
import AddRemoveController from './add_remove_controller'

const application = Application.start()

application.register('nested-form', NestedForm)
application.register('clipboard', Clipboard)
application.register('reveal', Reveal)
application.register('add-remove', AddRemoveController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
