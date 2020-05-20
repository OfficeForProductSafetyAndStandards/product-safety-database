require "rails_helper"

RSpec.feature "Adding a test result", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, team: create(:team)) }
  let(:investigation) { create(:allegation, products: [create(:product_washing_machine)], owner: user) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:date) { Faker::Date.backward(days: 14) }
  let(:file) { Rails.root + "test/fixtures/files/test_result.txt" }

  context "when user from another team" do
    scenario "doesn't allow to add test results" do
      sign_in(another_user_another_team)
      visit "/cases/#{investigation.pretty_id}/activity"
      page.should have_content("Add comment")
      page.should have_no_content("Add activity")
    end
  end

  context "when leaving the form fields empty" do
    scenario "shows error messages" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/activity/new"
      expect_to_be_on_new_activity_page

      expect_to_be_on_new_activity_page

      choose "activity_type_testing_result"
      click_button "Continue"

      expect_to_be_on_record_test_result_page
      click_button "Continue"

      expect(page).to have_summary_error("Enter date of the test")
      expect(page).to have_summary_error("Select the legislation that relates to this test")
      expect(page).to have_summary_error("Select result of the test")
      expect(page).to have_summary_error("Provide the test results file")
    end
  end

  context "with valid input data" do
    scenario "edit and saves the test result" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/activity/new"
      expect_to_be_on_new_activity_page

      within_fieldset "New activity" do
        page.choose "Record test result"
      end
      click_button "Continue"

      expect_to_be_on_record_test_result_page

      fill_in_test_result_submit_form(legislation: legislation, date: date, test_result: "test_result_passed", file: file)

      expect_test_result_confirmation_page_to_show_entered_data(legislation: legislation, date: date, test_result: "Passed")

      click_on "Edit details"

      expect_to_be_on_record_test_result_page

      expect_test_result_form_to_show_input_data(legislation: legislation, date: date)

      click_button "Continue"

      expect_test_result_confirmation_page_to_show_entered_data(legislation: legislation, date: date, test_result: "Passed")

      click_button "Continue"

      expect_confirmation_banner("Test result was successfully recorded.")
      expect_page_to_have_h1("Overview")
    end
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

  def expect_test_result_form_to_show_input_data(legislation:, date:)
    expect(page).to have_field("test_legislation", with: legislation)
    expect(page).to have_field("Day", with: date.day)
    expect(page).to have_field("Month", with: date.month)
    expect(page).to have_field("Year", with: date.year)
    expect(page).to have_field("test_result_passed", with: "passed")
    expect(page).to have_field("test_file_description", with: "\r\ntest result file")
  end

  def expect_test_result_confirmation_page_to_show_entered_data(legislation:, date:, test_result:)
    expect(page).to have_css("h1", text: "Confirm test result details")
    expect(page).to have_summary_table_item(key: "Legislation", value: legislation)
    expect(page).to have_summary_table_item(key: "Test date", value: date.strftime("%d/%m/%Y"))
    expect(page).to have_summary_table_item(key: "Test result", value: test_result)
    expect(page).to have_summary_table_item(key: "Attachment", value: File.basename(file))
    expect(page).to have_summary_table_item(key: "Attachment description", value: "test result file")
  end
end
