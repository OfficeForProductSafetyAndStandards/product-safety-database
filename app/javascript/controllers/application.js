'use strict'

import { Application } from '@hotwired/stimulus'
import CheckboxSelectAll from 'stimulus-checkbox-select-all'
import Clipboard from 'stimulus-clipboard'
import NestedForm from 'stimulus-rails-nested-form'
import Reveal from 'stimulus-reveal-controller'
import AddRemoveController from './add_remove_controller'

const application = Application.start()

application.register('checkbox-select-all', CheckboxSelectAll)
application.register('clipboard', Clipboard)
application.register('nested-form', NestedForm)
application.register('reveal', Reveal)
application.register('add-remove', AddRemoveController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
