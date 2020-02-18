require "rails_helper"
RSpec.feature "Adding a test results", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, products: [create(:product_washing_machine)], assignee: user) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:date) { Faker::Date.backward(days: 14) }
  let(:file) { Rails.root + "test/fixtures/files/old_risk_assessment.txt" }

  before { sign_in(as_user: user) }
  context "leaving the date and legistation field empty" do
    scenario "shows error messages" do
      visit new_investigation_activity_path(investigation)
      choose "activity_type_testing_result"
      click_button "Continue"
      expect(page).to have_css("h1", text: "Allegation: 2002-0001Record test result")
      click_button "Continue"
      expect(page).to have_css(".govuk-error-summary__list", text: "Enter date of the test")
      expect(page).to have_css(".govuk-error-summary__list", text: "Select the legislation that relates to this test")
      expect(page).to have_css(".govuk-error-summary__list", text: "Select result of the test")
      expect(page).to have_css(".govuk-error-summary__list", text: "Provide the test results file")
    end
  end
  context"with valid input data" do
    scenario "to be able to submit test results" do
      visit new_investigation_activity_path(investigation)
      choose "activity_type_testing_result"
      click_button "Continue"
      expect(page).to have_css("h1", text: "Allegation: 2002-0001Record test result")
      fill_in_submit_form
      expect_confirmation_page_to_show_entered_data
      click_button "Continue"
      validate_confirmation_banner("Test result was successfully recorded.")
    end
  end

  def fill_in_submit_form
    select legislation, from: "test_legislation"
    fill_in "Day", with: date.day if date
    fill_in "Month",   with: date.month if date
    fill_in "Year",    with: date.year  if date
    choose "test_result_passed"
    attach_file "test[file][file]", file
    fill_in "test_file_description", with: "test result file"
    click_button "Continue"
    expect(page).to have_css("h1", text: "Confirm test result details")
  end

  def expect_confirmation_page_to_show_entered_data
    expect(page).to have_summary_item(key: "Legislation", value: legislation)
    expect(page).to have_summary_item(key: "Test date", value: date.strftime("%d/%m/%Y"))
    expect(page).to have_summary_item(key: "Test result", value: "Passed")
    expect(page).to have_summary_item(key: "Attachment", value: File.basename(file))
    expect(page).to have_summary_item(key: "Attachment description", value: "test result file")

      # expect(page.find("th", text: "Legislation")).to have_sibling("td", text: legislation)
      # expect(page.find("th", text: "Test date")).to have_sibling("td", text: date.strftime("%d/%m/%Y"))
      # expect(page.find("th", text: "Test result")).to have_sibling("td", text: "Passed")
      # expect(page.find("th", text: "Attachment", match: :prefer_exact)).to have_sibling("td", text: File.basename(file))
      # expect(page.find("th", text: "Attachment description")).to have_sibling("td", text: "test result file")
    end
end
