require "rails_helper"

RSpec.feature "Adding a test result", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, products: [create(:product_washing_machine)], assignee: user) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:date) { Faker::Date.backward(days: 14) }
  let(:file) { Rails.root + "test/fixtures/files/test_result.txt" }

  before do
    sign_in(as_user: user)
    visit new_investigation_activity_path(investigation)
  end

  context "leaving the form fields empty" do
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

  context "with valid input data" do
    scenario "saves the test result" do
      expect(page).to have_css("h1", text: "New activity")

      within_fieldset "New activity" do
        page.choose "Record test result"
      end
      click_button "Continue"

      expect(page).to have_css("h1", text: "Allegation: 2002-0001Record test result")

      fill_in_test_result_submit_form(legislation: legislation, date: date, test_result: "test_result_passed", file: file)

      expect_confirmation_page_to_show_entered_data(legislation, date, "Passed")

      click_button "Continue"

      expect_confirmation_banner("Test result was successfully recorded.")
    end


    scenario "to able to see edit form" do
      expect(page).to have_css("h1", text: "New activity")

      within_fieldset "New activity" do
        page.choose "Record test result"
      end
      click_button "Continue"

      expect(page).to have_css("h1", text: "Allegation: 2002-0001Record test result")

      fill_in_test_result_submit_form(legislation: legislation, date: date, test_result: "test_result_passed", file: file)

      expect_confirmation_page_to_show_entered_data(legislation, date, "Passed")

      click_on "Edit details"

      expect_test_result_form_to_show_input_data(legislation, date)
    end
  end
end
