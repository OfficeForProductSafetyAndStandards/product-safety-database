require "rails_helper"
require "support/matchers/capybara_matchers"

RSpec.configure do |config|
  config.include PageMatchers
end

def expect_confirmation_banner(msg)
  expect(page).to have_css(".hmcts-banner__message", text: msg)
end

def fill_in_test_result_submit_form(legislation:, date:, test_result:, file:)
  select legislation, from: "test_legislation"
  fill_in "Day",   with: date.day if date
  fill_in "Month", with: date.month if date
  fill_in "Year",  with: date.year  if date
  choose test_result
  attach_file "test[file][file]", file
  fill_in "test_file_description", with: "test result file"
  click_button "Continue"
  expect(page).to have_css("h1", text: "Confirm test result details")
end

def expect_test_result_form_to_show_input_data(legislation, date)
  expect(page).to have_field("test_legislation", with: legislation)
  expect(page).to have_field("Day", with: date.day)
  expect(page).to have_field("Month", with: date.month)
  expect(page).to have_field("Year", with: date.year)
  expect(page).to have_field("test_result_passed", with: "passed")
  expect(page).to have_field("test_file_description", with: "\r\ntest result file")
end

def expect_confirmation_page_to_show_entered_data(legislation, date, test_result)
  expect(page).to have_css("h1", text: "Confirm test result details")
  expect(page).to have_summary_item(key: "Legislation", value: legislation)
  expect(page).to have_summary_item(key: "Test date", value: date.strftime("%d/%m/%Y"))
  expect(page).to have_summary_item(key: "Test result", value: test_result)
  expect(page).to have_summary_item(key: "Attachment", value: File.basename(file))
  expect(page).to have_summary_item(key: "Attachment description", value: "test result file")
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
