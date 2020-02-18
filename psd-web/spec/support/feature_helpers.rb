require "rails_helper"
require "support/matchers/capybara_matchers"

RSpec.configure do |config|
  config.include PageMatchers
end


def validate_confirmation_banner(msg)
  expect(page).to have_css(".hmcts-banner__message", text: msg)
end
