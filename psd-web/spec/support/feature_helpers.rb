require "rails_helper"
require "support/matchers/capybara_matchers"

RSpec.configure do |config|
  config.include PageMatchers
end

def have_summary_error(text)
  have_css(".govuk-error-summary__list", text: text)
end

def expect_confirmation_banner(msg)
  expect(page).to have_css(".hmcts-banner__message", text: msg)
end

def expect_page_to_have_h1(header)
  expect(page).to have_css("h1", text: header)
end

def enter_contact_details(contact_name:, contact_email:, contact_phone:)
  fill_in "complainant[name]", with: contact_name
  fill_in "complainant_email_address", with: contact_email
  fill_in "complainant_phone_number", with: contact_phone
  click_button "Continue"
end
