require "rails_helper"

RSpec.feature "Adding an accident or incident to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  include_context "with read only team and user"
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product1) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:product2) { create(:product_iphone, name: "iPhone 23") }
  let(:investigation) { create(:allegation, products: [product1, product2], creator: user, read_only_teams: read_only_team) }

  let(:date) { Date.parse("2020-05-01") }

  context "when the viewing user only has read only access" do
    scenario "cannot add supporting information" do
      sign_in(read_only_user)
      visit "/cases/#{investigation.pretty_id}/supporting-information"

      expect(page).not_to have_link("Add supporting information")
    end
  end

  scenario "Adding an accident or incident with date unknown, no custom severity and no additional info" do
    navigate_to_accident_or_incident_type_page

    expect_to_be_on_accident_or_incident_type_page

    expect(page).not_to have_error_messages

    click_button "Continue"

    expect(page).to have_error_messages

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the type of information you're adding"

    choose("Accident")

    click_button "Continue"

    expect_to_be_on_add_accident_or_incident_page("Accident")

    click_button "Add accident or incident"

    expect(page).to have_error_messages
    expect_ordered_error_list

    choose("No")
    select product1.name, from: "Select the product linked to this accident"
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

    expect_case_activity_page_to_show_entered_data("Unknown", "MyBrand Washing Machine", "Serious", "During normal use")

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page

    expect_summary_list_to_have(date: "Unknown", product_name: "MyBrand Washing Machine", severity: "Serious", usage: "During normal use", additional_info: "")
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

    expect_to_be_on_add_accident_or_incident_page("Accident")

    click_button "Add accident or incident"

    expect(page).to have_error_messages
    expect_ordered_error_list

    choose("Yes")
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    select product1.name, from: "Select the product linked to this accident"
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

    expect_case_activity_page_to_show_entered_data(date.to_s(:govuk), product1.name, "Test", "During normal use")

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page

    expect_summary_list_to_have(date: date.to_s(:govuk), product_name: product1.name, severity: "Test", usage: "During normal use", additional_info: "Some additional stuff you should know")
  end

  def expect_case_activity_page_to_show_entered_data(date, product_name, severity, usage)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: "Accident").find(:xpath, "..")
    expect(item).to have_text("Date of accident: #{date}")
    expect(item).to have_text("Product: #{product_name}")
    expect(item).to have_text("Severity: #{severity}")
    expect(item).to have_text("Product usage: #{usage}")
  end

  def expect_to_be_on_supporting_information_page
    expect(page).to have_css("h1", text: "Supporting information")
  end

  def expect_ordered_error_list
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select yes if you know when the accident or incident happened"
    expect(errors_list[1].text).to eq "Select the product linked to the accident or incident"
    expect(errors_list[2].text).to eq "Select the severity of the accident or incident"
    expect(errors_list[3].text).to eq "Select how the product was being used"
  end

  def expect_summary_list_to_have(date:, product_name:, severity:, usage:, additional_info:)
    expect(page).to have_summary_item(key: "Date of accident",      value: date)
    expect(page).to have_summary_item(key: "Product",               value: product_name)
    expect(page).to have_summary_item(key: "Severity",              value: severity)
    expect(page).to have_summary_item(key: "Product usage",         value: usage)
    expect(page).to have_summary_item(key: "Additional Info",       value: additional_info)
  end

  def navigate_to_accident_or_incident_type_page
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add new"

    expect_to_be_on_add_supporting_information_page

    choose "Accident or Incident"

    click_button "Continue"
  end
end
