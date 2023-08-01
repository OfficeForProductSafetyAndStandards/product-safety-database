require "rails_helper"

RSpec.feature "Adding a test result", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand washing machine") }
  let(:investigation) { create(:allegation, products: [product], creator: user) }
  let(:date) { Date.parse("1 Jan 2020") }
  let(:file) { Rails.root.join "test/fixtures/files/test_result.txt" }
  let(:other_user) { create(:user, :activated) }
  let(:legislation) { "General Product Safety Regulations 2005" }
  let(:failure_details) { "Something went wrong" }

  scenario "Adding a passing test result (with validation errors)" do
    travel_to Date.parse("2 April 2020") do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}"
      click_link "Add a test result"

      expect_to_be_on_record_test_result_opss_funding_decision_page(case_id: investigation.pretty_id)
      expect_to_have_case_breadcrumbs
      within_fieldset "Was the test funded under the OPSS Sampling Protocol?" do
        page.choose "No"
      end
      click_button "Continue"

      expect_to_be_on_record_test_result_page
      expect_test_result_form_to_be_blank
      expect_to_have_case_breadcrumbs

      click_button "Add test result"

      expect_full_error_list

      fill_in "Further details", with: "Test result includes certificate of conformity"
      fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")

      expect_confirmation_banner("The supporting information was updated")
      expect_page_to_have_h1("Supporting information")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_activity_page_to_show_created_unfunded_test_result_values(result: "Passed")

      click_link "View test result"

      expect_to_be_on_test_result_page(case_id: investigation.pretty_id)
      expect_to_have_case_breadcrumbs
      expect_summary_to_reflect_values(result: "Pass")

      expect(page).to have_text("test_result.txt")

      visit "/cases/#{investigation.pretty_id}/test-results/new"
      expect_test_result_form_to_be_blank
    end
  end

  scenario "Adding a passing test result funded by OPSS" do
    travel_to Date.parse("2 April 2020") do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}"
      click_link "Add a test result"

      expect_to_be_on_record_test_result_opss_funding_decision_page(case_id: investigation.pretty_id)
      expect_to_have_case_breadcrumbs
      within_fieldset "Was the test funded under the OPSS Sampling Protocol?" do
        page.choose "Yes"
      end
      click_button "Continue"

      expect_to_be_on_record_test_result_opss_funding_form_page(case_id: investigation.pretty_id)
      expect_to_have_case_breadcrumbs
      fill_in "What is the TSO Sample Reference Number?", with: "TSO123"
      click_button "Continue"
      expect_certificate_date_error

      fill_in "Day", with: date.day
      fill_in "Month", with: date.month
      fill_in "Year", with: date.year
      click_button "Continue"

      expect_to_be_on_record_test_result_page
      expect_test_result_form_to_be_blank
      expect_to_have_case_breadcrumbs

      click_button "Add test result"

      expect_full_error_list
      expect_to_have_case_breadcrumbs

      fill_in "Further details", with: "Test result includes certificate of conformity"
      fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")

      expect_confirmation_banner("The supporting information was updated")
      expect_page_to_have_h1("Supporting information")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_activity_page_to_show_created_funded_test_result_values(result: "Passed", funded_date: date)

      click_link "View test result"

      expect_to_be_on_test_result_page(case_id: investigation.pretty_id)

      expect_summary_to_reflect_values(result: "Pass", funded: true)

      expect(page).to have_text("test_result.txt")

      visit "/cases/#{investigation.pretty_id}/test-results/new"
      expect_test_result_form_to_be_blank
    end
  end

  scenario "Adding a failing test result (with validation errors)" do
    travel_to Date.parse("2 April 2020") do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}"
      click_link "Add a test result"

      expect_to_be_on_record_test_result_opss_funding_decision_page(case_id: investigation.pretty_id)
      expect_to_have_case_breadcrumbs
      within_fieldset "Was the test funded under the OPSS Sampling Protocol?" do
        page.choose "No"
      end
      click_button "Continue"

      expect_to_be_on_record_test_result_page
      expect_test_result_form_to_be_blank
      expect_to_have_case_breadcrumbs

      click_button "Add test result"

      expect_full_error_list

      within_fieldset "What was the result?" do
        choose "Fail"
      end

      click_button "Add test result"

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[3].text).to eq "Enter details about how the product failed to meet the requirements"

      fill_in "Further details", with: "Test result includes certificate of conformity"
      fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Fail", failure_details:, file:, standards: "EN71, EN73")

      expect_confirmation_banner("The supporting information was updated")
      expect_page_to_have_h1("Supporting information")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_activity_page_to_show_created_unfunded_test_result_values(result: "Failed")

      click_link "View test result"

      expect_to_be_on_test_result_page(case_id: investigation.pretty_id)

      expect_summary_to_reflect_values(result: "Fail")

      expect(page).to have_text("test_result.txt")

      visit "/cases/#{investigation.pretty_id}/test-results/new"
      expect_test_result_form_to_be_blank
    end
  end

  scenario "Not being able to add test results to another team's case" do
    sign_in(other_user)
    visit "/cases/#{investigation.pretty_id}/activity"

    expect(page).not_to have_link("Add a test result")
  end

  def fill_in_test_result_submit_form(legislation:, date:, test_result:, file:, standards:, failure_details: nil)
    select legislation, from: "Under which legislation?"
    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
    fill_in "Which standard was the product tested against?", with: standards
    within_fieldset "What was the result?" do
      choose test_result
      if test_result == "Fail"
        fill_in "How the product failed", with: failure_details
      end
    end
    within_fieldset "Test report attachment" do
      attach_file file
      fill_in "Attachment description", with: "test result file"
    end

    click_button "Add test result"
  end

  def expect_test_result_form_to_be_blank
    expect(page).to have_field("Under which legislation?", with: nil)
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
    expect(page).to have_field("Under which legislation?", with: legislation)
    expect(page).to have_field("Day", with: date.day)
    expect(page).to have_field("Month", with: date.month)
    expect(page).to have_field("Year", with: date.year)
    within_fieldset("What was the result?") do
      expect(page).to have_checked_field("Pass")
    end
    within_fieldset "Test report attachment" do
      expect(page).to have_field("Attachment description", with: "test result file")
    end
  end

  def expect_certificate_date_error
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter the date the test certificate was issued"
  end

  def expect_full_error_list
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the legislation that relates to this test"
    expect(errors_list[1].text).to eq "Enter the standard the product was tested against"
    expect(errors_list[2].text).to eq "Enter date of the test"
    expect(errors_list[3].text).to eq "Select result of the test"
    expect(errors_list[4].text).to eq "Provide the test results file"
  end

  def expect_summary_to_reflect_values(result:, funded: false)
    expect(page).to have_summary_item(key: "Date of test", value: "1 January 2020")
    expect(page).to have_summary_item(key: "Legislation", value: "General Product Safety Regulations 2005")
    expect(page).to have_summary_item(key: "Standards", value: "EN71, EN73")
    expect(page).to have_summary_item(key: "Result", value: result)
    if funded
      expect(page).to have_summary_item(key: "Funded", value: "Yes Funded under the OPSS Sampling Protocol")
    else
      expect(page).to have_summary_item(key: "Funded", value: "No")
    end
    expect(page).to have_summary_item(key: "Further details", value: "Test result includes certificate of conformity")
    expect(page).to have_summary_item(key: "Attachment description", value: "test result file")
  end

  def expect_activity_page_to_show_created_unfunded_test_result_values(result:)
    expect(page).to have_text("#{result} test: MyBrand washing machine")
    expect(page).to have_text(product.name)
    expect(page).to have_text("Legislation: General Product Safety Regulations 2005")
    expect(page).to have_text("Standards: EN71, EN73")
    expect(page).to have_text("Date of test: 1 January 2020")
    expect(page).to have_text("Further details: Test result includes certificate of conformity")
    expect(page).to have_text("File description: test result file")
    expect(page).to have_text("Funded: No")
    expect(page).to have_text("Test result includes certificate of conformity")
    expect(page).to have_link("test_result.txt")
  end

  def expect_activity_page_to_show_created_funded_test_result_values(result:, funded_date:)
    expect(page).to have_text("#{result} test: MyBrand washing machine")
    expect(page).to have_text(product.name)
    expect(page).to have_text("Legislation: General Product Safety Regulations 2005")
    expect(page).to have_text("Standards: EN71, EN73")
    expect(page).to have_text("Date of test: 1 January 2020")
    expect(page).to have_text("Further details: Test result includes certificate of conformity")
    expect(page).to have_text("File description: test result file")
    expect(page).to have_text("Funded: Yes")
    expect(page).to have_text("Issue date: #{funded_date.to_formatted_s(:govuk)}")
    expect(page).to have_text("Test result includes certificate of conformity")
    expect(page).to have_link("test_result.txt")
  end
end
