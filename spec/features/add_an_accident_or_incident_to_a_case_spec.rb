require "rails_helper"

RSpec.feature "Adding an accident or incident to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  include_context "with read only team and user"
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:investigation) { create(:allegation, products: [product], creator: user, read_only_teams: read_only_team) }

  let(:date) { Date.parse("2020-05-01") }

  context "when the viewing user only has read only access" do
    scenario "cannot add supporting information" do
      sign_in(read_only_user)
      visit "/cases/#{investigation.pretty_id}/supporting-information"

      expect(page).not_to have_link("Add supporting information")
    end
  end

  scenario "Adding an accident or incident with date unknown, no custom severity and no additional info" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add new"

    expect_to_be_on_add_supporting_information_page

    choose "Accident or Incident"

    click_button "Continue"

    expect_to_be_on_accident_or_incident_type_page

    expect(page).not_to have_error_messages

    click_button "Continue"

    expect(page).to have_error_messages

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the type of information you're adding"

    choose("Accident")

    click_button "Continue"

    expect_to_be_on_add_accident_or_incident_page("accident")

    click_button "Add accident or incident"

    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select yes if you know when the accident or incident happened"
    expect(errors_list[1].text).to eq "Select the product linked to the accident or incident"
    expect(errors_list[2].text).to eq "Select the severity of the accident or incident"
    expect(errors_list[3].text).to eq "Select how the product was being used"

    choose("No")
    select "MyBrand Washing Machine", from: "Select the product linked to this accident"
    choose("Serious")
    choose("During normal use")

    expect(page).to have_error_messages
    click_button "Add accident or incident"

    expect(page).not_to have_error_messages

    expect(page).to have_content "Supporting information"
    expect(page).to have_content "During normal use: MyBrand Washing Machine"

    expect_to_be_on_supporting_information_page

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect_case_activity_page_to_show_entered_data

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page

    expect(page).to have_summary_item(key: "Date of accident",      value: "")
    expect(page).to have_summary_item(key: "Product",               value: "MyBrand Washing Machine")
    expect(page).to have_summary_item(key: "Severity",              value: "Serious")
    expect(page).to have_summary_item(key: "Product usage",         value: "During normal use")
    expect(page).to have_summary_item(key: "Additional Info",       value: "")
  end

  scenario "Adding an accident or incident with date known, custom severity and additional info" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add new"

    expect_to_be_on_add_supporting_information_page

    choose "Accident or Incident"

    click_button "Continue"

    expect_to_be_on_accident_or_incident_type_page

    expect(page).not_to have_error_messages

    click_button "Continue"

    expect(page).to have_error_messages

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the type of information you're adding"

    choose("Accident")

    click_button "Continue"

    expect_to_be_on_add_accident_or_incident_page("accident")

    click_button "Add accident or incident"

    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select yes if you know when the accident or incident happened"
    expect(errors_list[1].text).to eq "Select the product linked to the accident or incident"
    expect(errors_list[2].text).to eq "Select the severity of the accident or incident"
    expect(errors_list[3].text).to eq "Select how the product was being used"

    choose("Yes")
    fill_in("Day", with: "3")
    fill_in("Month", with: "4")
    fill_in("Year", with: "2020")
    select "MyBrand Washing Machine", from: "Select the product linked to this accident"
    choose("Other")
    fill_in "Other type", with: "Test"
    choose("During normal use")
    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Add accident or incident"

    expect(page).not_to have_error_messages

    expect(page).to have_content "During normal use: MyBrand Washing Machine"

    expect_to_be_on_supporting_information_page

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect_case_activity_page_to_show_entered_data

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page

    expect(page).to have_summary_item(key: "Date of accident",      value: "2020-04-03")
    expect(page).to have_summary_item(key: "Product",               value: "MyBrand Washing Machine")
    expect(page).to have_summary_item(key: "Severity",              value: "Test")
    expect(page).to have_summary_item(key: "Product usage",         value: "During normal use")
    expect(page).to have_summary_item(key: "Additional Info",       value: "Some additional stuff you should know")
  end

  def expect_case_activity_page_to_show_entered_data
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: "Accident or Incident").find(:xpath, "..")
    byebug
    expect(item).to have_text("Date of accident: #{Date.new(2020, 0o4, 0o3)}")
    expect(item).to have_text("Product: MyBrand Washing Machine")
    expect(item).to have_text("Severity: Serious")
    expect(item).to have_text("Product usage: During normal use")
  end

  def expect_to_be_on_supporting_information_page
    expect(page).to have_css("h1", text: "Supporting information")
  end

  # def fill_and_submit_form
  #   choose action
  #   fill_in "Day",     with: date.day   if date
  #   fill_in "Month",   with: date.month if date
  #   fill_in "Year",    with: date.year  if date
  #
  #   select legislation, from: "Under which legislation?"
  #
  #   fill_in "Further details (optional)", with: details
  #
  #   within_fieldset "Are there any files related to the action?" do
  #     choose "Yes"
  #   end
  #
  #   attach_file "Upload a file", file
  #
  #   fill_in "Attachment description", with: file_description
  #
  #   within_fieldset "Is the corrective action mandatory?" do
  #     choose "Yes"
  #   end
  #
  #   within_fieldset "How long will the corrective action be in place?" do
  #     choose duration
  #   end
  #
  #   select geographic_scope, from: "What is the geographic scope of the action?"
  #
  #   fill_in "Further details (optional)", with: "Urgent action following consumer reports"
  #   click_button "Continue"
  # end
end
