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

def expect_h1_on_the_page(header)
  expect(page).to have_css("h1", text: header)
end

def enter_contact_details(contact_name:, contact_email:, contact_phone:)
  fill_in "complainant[name]", with: contact_name
  fill_in "complainant_email_address", with: contact_email
  fill_in "complainant_phone_number", with: contact_phone
  click_button "Continue"
end

def enter_allegation_details(description:, hazard_type:, category:)
  expect(page).to have_css("h1", text: "New allegation")
  fill_in "allegation_description", with: description
  select category, from: "allegation_product_category"
  select hazard_type, from: "allegation_hazard_type"
  click_button "Create allegation"
end

def enter_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:)
  select category, from: "Product category"
  select country_of_origin, from: "Country of origin"
  fill_in "Product type",               with: type
  fill_in "Product name",               with: name
  fill_in "Barcode or serial number",   with: barcode
  fill_in "Webpage",                    with: webpage
  fill_in "Description of product",     with: description
  click_button "Save product"
end

def expect_page_to_show_entered_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:)
  expect(page.find("dt", text: "Product name")).to have_sibling("dd", text: name)
  expect(page.find("dt", text: "Product type")).to have_sibling("dd", text: type)
  expect(page.find("dt", text: "Category")).to have_sibling("dd", text: category)
  expect(page.find("dt", text: "Barcode or serial number")).to have_sibling("dd", text: barcode)
  expect(page.find("dt", text: "Webpage")).to have_sibling("dd", text: webpage)
  expect(page.find("dt", text: "Country of origin")).to have_sibling("dd", text: country_of_origin)
  expect(page.find("dt", text: "Description")).to have_sibling("dd", text: description)
end
