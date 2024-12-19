require "rails_helper"

RSpec.feature "Add or remove test report during Edit Notification journey", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let!(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:product_one) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let!(:product_two) { create(:product_iphone, name: "iPhone 23") }
  let!(:notification) { create(:notification, :with_business, products: [product_one, product_two], creator: user, reported_reason: "unsafe_and_non_compliant", hazard_type: "Burns", hazard_description: "FIRE", non_compliant_reason: "danger") }
  let(:file) { Rails.root.join "test/fixtures/files/test_result.txt" }
  let(:date) { Date.parse("1 Jan 2023") }

  before do
    sign_in(user)
  end

  scenario "Edit Test report during the edit Notification journey follows right flow" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    expect(page).to have_content(notification.user_title)

    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    expect(page).to have_breadcrumb("Notifications")
    expect(page).to have_content("Was the test funded under the OPSS sampling protocol for Local Authorities?")
    choose "Yes"
    click_button "Save and continue"

    expect(page).to have_breadcrumb("Notifications")
    expect(page).to  have_content("Add the test certificate details")

    fill_in "What is the trading standards officer sample reference number?", with: "TSO123"

    fill_in "Day", with: date.day
    fill_in "Month", with: date.month
    fill_in "Year", with: date.year
    click_button "Save and continue"

    expect(page).to have_breadcrumb("Notifications")
    expect(page).to  have_content("Add test report")

    fill_in "Further details", with: "Test result includes certificate of conformity"
    fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")
    expect_confirmation_banner("Test report uploaded successfully.")

    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end

    click_button "Save and continue"
    expect(page).to have_current_path("/notifications/#{notification.pretty_id}", ignore_query: true)
  end

  scenario "Add test report journey , when the test was not funded by OPSS" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    expect(page).to have_content(notification.user_title)

    click_link "Change test reports (#{product_one.decorate.name_with_brand})"

    expect(page).to  have_content("Was the test funded under the OPSS sampling protocol for Local Authorities?")
    choose "No"
    click_button "Save and continue"

    expect(page).not_to have_content("Add the test certificate details")

    expect(page).to  have_content("Add test report")

    fill_in "Further details", with: "Test result includes certificate of conformity"
    fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")
    expect_confirmation_banner("Test report uploaded successfully.")

    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end

    click_button "Save and continue"
    expect(page).to have_current_path("/notifications/#{notification.pretty_id}", ignore_query: true)
  end

  scenario "Add test report journey , when there are tests already associated to the Product" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    expect(page).to have_content(notification.user_title)
    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    expect(page).to  have_content("Was the test funded under the OPSS sampling protocol for Local Authorities?")
    choose "No"
    click_button "Save and continue"
    fill_in "Further details", with: "Test result includes certificate of conformity"
    fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")
    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end
    click_button "Save and continue"
    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    expect(page).to  have_content("Add test reports")
    expect(page).to  have_content("You have added 1 test report.")
    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end

    click_button "Save and continue"
    expect(page).to have_current_path("/notifications/#{notification.pretty_id}", ignore_query: true)
  end

  scenario "Add test report journey , Edit an already existing Test report" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    expect(page).to have_content(notification.user_title)
    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    expect(page).to  have_content("Was the test funded under the OPSS sampling protocol for Local Authorities?")
    choose "No"
    click_button "Save and continue"
    fill_in "Further details", with: "Test result includes certificate of conformity"
    fill_in_test_result_submit_form(legislation: "General Product Safety Regulations 2005", date:, test_result: "Pass", file:, standards: "EN71, EN73")
    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end
    click_button "Save and continue"
    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    expect(page).to  have_content("Add test reports")
    expect(page).to  have_content("You have added 1 test report.")

    click_link "Change"
    fill_in "Further details", with: "Updated Test result includes certificate of conformity"
    click_button "Update test report"
    expect_confirmation_banner("Test report updated successfully.")
    within_fieldset "Do you need to add another test report?" do
      choose "No"
    end
    click_button "Save and continue"
    expect(page).to have_current_path("/notifications/#{notification.pretty_id}", ignore_query: true)
  end

  scenario "Expect validation errors when mandatory fields are not entered" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    click_link "Change test reports (#{product_one.decorate.name_with_brand})"
    choose "Yes"
    click_button "Save and continue"

    expect(page).to have_content("Add the test certificate details")
    click_button "Save and continue"
    expect_certificate_date_error

    fill_in "Day", with: date.day
    fill_in "Month", with: date.month
    fill_in "Year", with: date.year
    click_button "Save and continue"
    expect(page).to have_content("Add test report")
    click_button "Add test report"
    expect_full_error_list
  end

  def fill_in_test_result_submit_form(legislation:, date:, test_result:, file:, standards:)
    select legislation, from: "Under which legislation?"
    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
    fill_in "Which standard was the product tested against?", with: standards
    within_fieldset "What was the result?" do
      choose test_result
    end
    attach_file "test_result_form[document]", file

    click_button "Add test report"
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
end
