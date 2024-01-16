require "support/matchers/capybara_matchers"

RSpec.configure do |config|
  config.include PageMatchers
end

def expect_confirmation_banner(msg)
  expect(page).to have_css(".govuk-notification-banner--success", text: msg)
end

def expect_warning_banner(msg)
  expect(page).to have_css(".govuk-notification-banner", text: msg)
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

def fill_in_credentials(password_override: nil)
  fill_in "Email address", with: user.email
  if password_override
    fill_in "Password", with: password_override
  else
    fill_in "Password", with: password
  end
  click_on "Continue"
end
