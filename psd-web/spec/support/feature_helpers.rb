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
  fill_in "Day", with: date.day if date
  fill_in "Month",   with: date.month if date
  fill_in "Year",    with: date.year  if date
  choose test_result
  attach_file "test[file][file]", file
  fill_in "test_file_description", with: "test result file"
  click_button "Continue"
  expect(page).to have_css("h1", text: "Confirm test result details")
end

def expect_test_result_form_to_show_input_data(legislation:, date:)
  expect(page).to have_field("test_legislation", with: legislation)
  expect(page).to have_field("Day", with: date.day)
  expect(page).to have_field("Month", with: date.month)
  expect(page).to have_field("Year", with: date.year)
  expect(page).to have_field("test_result_passed", with: "passed")
  expect(page).to have_field("test_file_description", with: "\r\ntest result file")
end

def expect_confirmation_page_to_show_entered_data(legislation:, date:, test_result:)
  expect(page).to have_css("h1", text: "Confirm test result details")
  expect(page).to have_summary_item(key: "Legislation", value: legislation)
  expect(page).to have_summary_item(key: "Test date", value: date.strftime("%d/%m/%Y"))
  expect(page).to have_summary_item(key: "Test result", value: test_result)
  expect(page).to have_summary_item(key: "Attachment", value: File.basename(file))
  expect(page).to have_summary_item(key: "Attachment description", value: "test result file")
end
