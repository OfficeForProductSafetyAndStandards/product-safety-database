require "rails_helper"

RSpec.feature "Adding a test result", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand washing machine") }
  let(:investigation) { create(:allegation, products: [product], creator: user) }
  let(:date) { Date.parse("1 Jan 2020") }
  let(:file) { Rails.root + "test/fixtures/files/test_result.txt" }
  let(:other_user) { create(:user, :activated) }
  let(:legislation) { "General Product Safety Regulations 2005" }

  scenario "Adding a test result (with validation errors)" do
    travel_to Date.parse("2 April 2020") do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/supporting-information"

      click_link "Add supporting information"

      expect_to_be_on_add_supporting_information_page

      within_fieldset "What type of information are you adding?" do
        page.choose "Test result"
      end
      click_button "Continue"

      expect_to_be_on_record_test_result_page
      expect_test_result_form_to_be_blank

      click_button "Add test result"

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Select the legislation that relates to this test"
      expect(errors_list[1].text).to eq "Enter date of the test"
      expect(errors_list[2].text).to eq "Select result of the test"
      expect(errors_list[3].text).to eq "Provide the test results file"

      fill_in "Further details", with: "Test result includes certificate of conformity"
      fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date: date, test_result: "Pass", file: file, standards: "EN71, EN73")

      expect_confirmation_banner("Test result was successfully recorded.")
      expect_page_to_have_h1("Supporting information")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect(page).to have_text("Passed test: MyBrand washing machine")

      click_link "View test result"

      expect_to_be_on_test_result_page(case_id: investigation.pretty_id)

      expect(page).to have_summary_item(key: "Date of test", value: "1 January 2020")
      expect(page).to have_summary_item(key: "Legislation", value: "General Product Safety Regulations 2005")
      expect(page).to have_summary_item(key: "Standards", value: "EN71, EN73")
      expect(page).to have_summary_item(key: "Result", value: "Passed")
      expect(page).to have_summary_item(key: "Further details", value: "Test result includes certificate of conformity")
      expect(page).to have_summary_item(key: "Attachment description", value: "test result file")

      expect(page).to have_text("test_result.txt")

      visit "/cases/#{investigation.pretty_id}/test-results/new"
      expect_test_result_form_to_be_blank
    end
  end

  scenario "Not being able to add test results to another team’s case" do
    sign_in(other_user)
    visit "/cases/#{investigation.pretty_id}/activity"

    expect(page).not_to have_link("Add supporting information")
  end

  def fill_in_test_result_submit_form(legislation:, date:, test_result:, file:, standards:)
    select legislation, from: "Against which legislation?"
    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
    fill_in "Which standard was the product tested against?", with: standards
    within_fieldset "What was the result?" do
      choose test_result
    end
    within_fieldset "Test report attachment" do
      attach_file file
      fill_in "Attachment description", with: "test result file"
    end

    click_button "Add test result"
  end

  def expect_test_result_form_to_be_blank
    expect(page).to have_field("Against which legislation?", with: nil)
    expect(page.find_field("Day").text).to be_blank
    expect(page.find_field("Month").text).to be_blank
    expect(page.find_field("Year").text).to be_blank
    within_fieldset("What was the result?") do
      expect(page).not_to have_checked_field("Pass")
      expect(page).not_to have_checked_field("Fail")
      expect(page).not_to have_checked_field("Other")
    end
    within_fieldset "Test report attachment" do
      expect(page.find_field("Upload a file").value).to be_blank
      expect(page.find_field("Attachment description").text).to be_blank
    end
  end

  def expect_test_result_form_to_show_input_data(legislation:, date:)
    expect(page).to have_field("Against which legislation?", with: legislation)
    expect(page).to have_field("Day", with: date.day)
    expect(page).to have_field("Month", with: date.month)
    expect(page).to have_field("Year", with: date.year)
    within_fieldset("What was the result?") do
      expect(page).to have_checked_field("Pass")
    end
    within_fieldset "Test report attachment" do
      expect(page).to have_field("Attachment description", with: "\r\ntest result file")
    end
  end
end
