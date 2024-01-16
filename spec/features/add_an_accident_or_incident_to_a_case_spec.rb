RSpec.feature "Adding an accident or incident to a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  include_context "with read only team and user"
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product1) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:product2) { create(:product_iphone, name: "iPhone 23") }
  let(:investigation) { create(:allegation, products: [product1, product2], creator: user, read_only_teams: read_only_team) }

  let(:date) { Date.parse("2020-05-01") }

  context "when the viewing user only has read only access" do
    scenario "cannot add supporting information" do
      sign_in(read_only_user)
      visit "/cases/#{investigation.pretty_id}"
      expect(page).not_to have_link("Add an incident or accident")
    end
  end

  scenario "Adding an accident or incident with date unknown, no custom severity and no additional info" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"
    click_link "Add an accident or incident"

    expect_to_be_on_accident_or_incident_type_page
    expect_to_have_notification_breadcrumbs

    expect(page).not_to have_error_messages

    click_button "Continue"

    expect(page).to have_error_messages
    expect_to_have_notification_breadcrumbs

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the type of information you're adding"

    choose("Accident")

    click_button "Continue"

    expect_to_be_on_add_accident_or_incident_page("Accident")
    expect_to_have_notification_breadcrumbs

    click_button "Add accident"

    expect(page).to have_error_messages
    expect_ordered_error_list

    choose("No")
    select product1.name, from: "Which product was involved?"
    choose("Serious")
    choose("Normal use")

    expect(page).to have_error_messages
    click_button "Add accident"

    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    expect(page).to have_content "Supporting information"
    expect(page).to have_content "MyBrand Washing Machine #{product1.psd_ref}: Normal use"

    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs

    expect_case_activity_page_to_show_entered_data("Unknown", "MyBrand Washing Machine", "Serious", "Normal use")

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page

    expect_summary_list_to_have(date: "Unknown", product_name: "MyBrand Washing Machine (#{product1.psd_ref})", severity: "Serious", usage: "Normal use", additional_info: "")
  end

  scenario "Adding an accident or incident with date known, custom severity and additional info" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"
    click_link "Add an accident or incident"

    expect_to_be_on_accident_or_incident_type_page
    expect_to_have_notification_breadcrumbs

    expect(page).not_to have_error_messages

    click_button "Continue"

    expect(page).to have_error_messages
    expect_to_have_notification_breadcrumbs

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select the type of information you're adding"

    choose("Accident")

    click_button "Continue"

    expect_to_be_on_add_accident_or_incident_page("Accident")
    expect_to_have_notification_breadcrumbs

    click_button "Add accident"

    expect(page).to have_error_messages
    expect_ordered_error_list
    expect_to_have_notification_breadcrumbs

    choose("Yes")
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    select product1.name, from: "Which product was involved?"
    choose("Other")
    fill_in "Other type", with: "Test"
    choose("Normal use")
    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Add accident"

    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    expect(page).to have_content "MyBrand Washing Machine #{product1.psd_ref}: Normal use"

    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs
    expect_case_activity_page_to_show_entered_data(date.to_formatted_s(:govuk), product1.name, "Test", "Normal use")

    click_link "View accident"

    expect_to_be_on_show_accident_or_incident_page
    expect_to_have_notification_breadcrumbs

    expect_summary_list_to_have(date: date.to_formatted_s(:govuk), product_name: "#{product1.name} (#{product1.psd_ref})", severity: "Test", usage: "Normal use", additional_info: "Some additional stuff you should know")
  end

  def expect_case_activity_page_to_show_entered_data(date, product_name, severity, usage)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: "Accident").find(:xpath, "..")
    expect(item).to have_text("Date of accident: #{date}")
    expect(item).to have_text("Product: #{product_name}")
    expect(item).to have_text("Severity: #{severity}")
    expect(item).to have_text("Product usage: #{usage}")
  end

  def expect_ordered_error_list
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select yes if you know when the accident happened"
    expect(errors_list[1].text).to eq "Select the product involved in the accident"
    expect(errors_list[2].text).to eq "Select how the product was being used"
    expect(errors_list[3].text).to eq "Select the severity of the accident"
  end

  def expect_summary_list_to_have(date:, product_name:, severity:, usage:, additional_info:)
    expect(page).to have_summary_item(key: "Date of accident",      value: date)
    expect(page).to have_summary_item(key: "Product",               value: product_name)
    expect(page).to have_summary_item(key: "Severity",              value: severity)
    expect(page).to have_summary_item(key: "Product usage",         value: usage)
    if additional_info.present?
      expect(page).to have_summary_item(key: "Additional Information", value: additional_info)
    end
  end
end
