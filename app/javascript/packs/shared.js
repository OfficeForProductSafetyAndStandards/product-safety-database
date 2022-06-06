// JS
import 'core-js/stable'
import 'regenerator-runtime/runtime'

import Rails from 'rails-ujs'
import { initAll } from 'govuk-frontend'
initAll()

import 'javascripts/location_picker'
import 'javascripts/autocomplete'
import 'javascripts/cookie_banner'
import 'javascripts/_menu'

import 'javascripts/investigations/attachment_description'
import 'javascripts/investigations/sort_dropdown'
import 'javascripts/investigations/ts_investigations/which_businesses'
import 'javascripts/mutually_exclusive'
import 'javascripts/close_page_button'
import 'javascripts/date_input'
import 'javascripts/clear_on_reset'

// CSS
import 'accessible-autocomplete/src/autocomplete.css'

// Images
import 'govuk-frontend/govuk/assets/images/favicon.ico'
import 'govuk-frontend/govuk/assets/images/govuk-mask-icon.svg'
import 'govuk-frontend/govuk/assets/images/govuk-crest-2x.png'
import 'govuk-frontend/govuk/assets/images/govuk-apple-touch-icon-180x180.png'
import 'govuk-frontend/govuk/assets/images/govuk-apple-touch-icon-167x167.png'
import 'govuk-frontend/govuk/assets/images/govuk-apple-touch-icon-152x152.png'
import 'govuk-frontend/govuk/assets/images/govuk-apple-touch-icon.png'
import 'govuk-frontend/govuk/assets/images/govuk-opengraph-image.png'
import 'govuk-frontend/govuk/assets/images/govuk-logotype-crown.png'

import 'images/document_placeholder_document.png'
import 'images/document_placeholder_spreadsheet.png'
import 'images/img-icon.png'

Rails.start()
