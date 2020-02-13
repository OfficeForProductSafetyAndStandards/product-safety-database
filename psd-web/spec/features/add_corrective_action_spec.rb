require "rails_helper"

RSpec.feature "Adding a correcting action to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, products: [create(:product_washing_machine)], assignee: user) }

  let(:summary) { Faker::Lorem.sentence }
  let(:date) { Faker::Date.backward(days: 14) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:details) { Faker::Lorem.sentence }
  let(:file) { Rails.root + "test/fixtures/files/old_risk_assessment.txt" }
  let(:file_description) { Faker::Lorem.paragraph }
  let(:measure_type) { CorrectiveAction::MEASURE_TYPES.sample }
  let(:duration) { CorrectiveAction::DURATION_TYPES.sample }
  let(:geographic_scope) { Rails.application.config.corrective_action_constants["geographic_scope"].sample }

  before { sign_in(as_user: user) }

  context "with valid input" do
    scenario "shows inputted data on the confirmation page and on the case attachments and activity pages" do
      visit new_investigation_corrective_action_path(investigation)

      expect_to_be_on_record_corrective_action_page
      fill_and_submit_form

      expect_to_be_on_confirmation_page
      expect_confirmation_page_to_show_entered_data

      click_on "Continue"

      expect_to_be_on_case_overview_page

      click_on "Activity"

      expect_case_activity_page_to_show_entered_data

      click_on "Attachments (1)"

      expect_case_attachments_page_to_show_file
    end

    scenario "going back to the form from the confirmation page shows inputted data" do
      visit new_investigation_corrective_action_path(investigation)

      expect_to_be_on_record_corrective_action_page
      fill_and_submit_form

      expect_to_be_on_confirmation_page
      expect_confirmation_page_to_show_entered_data

      click_link "Edit details"

      expect_form_to_show_input_data
    end
  end

  context "with invalid input" do
    let(:date) { nil }

    scenario "shows an error message" do
      visit new_investigation_corrective_action_path(investigation)

      expect_to_be_on_record_corrective_action_page
      fill_and_submit_form

      expect(page).to have_error_messages
    end
  end

  def expect_to_be_on_record_corrective_action_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/corrective_actions/details")
    expect(page).to have_selector("h1", text: "Record corrective action")
    expect(page).not_to have_error_messages
  end

  def expect_to_be_on_confirmation_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/corrective_actions/confirmation")
    expect(page).to have_selector("h1", text: "Confirm corrective action details")
    expect(page).not_to have_error_messages
  end

  def expect_to_be_on_case_overview_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
    expect(page).to have_selector("h1", text: "Overview")
    expect(page).not_to have_error_messages
  end

  def expect_confirmation_page_to_show_entered_data
    expect(page.find("th", text: "Summary")).to have_sibling("td", text: summary)
    expect(page.find("th", text: "Date decided")).to have_sibling("td", text: date.strftime("%d/%m/%Y"))
    expect(page.find("th", text: "Legislation")).to have_sibling("td", text: legislation)
    expect(page.find("th", text: "Details")).to have_sibling("td", text: details)
    expect(page.find("th", text: "Attachment", match: :prefer_exact)).to have_sibling("td", text: File.basename(file))
    expect(page.find("th", text: "Attachment description")).to have_sibling("td", text: file_description)
    expect(page.find("th", text: "Type of measure")).to have_sibling("td", text: CorrectiveAction.human_attribute_name("measure_type.#{measure_type}"))
    expect(page.find("th", text: "Duration of action")).to have_sibling("td", text: CorrectiveAction.human_attribute_name("duration.#{duration}"))
    expect(page.find("th", text: "Geographic scope")).to have_sibling("td", text: geographic_scope)
  end

  def expect_form_to_show_input_data
    expect(page).to have_field("Summary", with: summary)
    expect(page).to have_field("Day", with: date.day)
    expect(page).to have_field("Month", with: date.month)
    expect(page).to have_field("Year", with: date.year)
    expect(page).to have_field("Under which legislation?", with: legislation)
    expect(page).to have_checked_field("corrective_action_measure_type_#{measure_type}")
    expect(page).to have_checked_field("corrective_action_duration_#{duration}")
    expect(page).to have_field("What is the geographic scope of the action?", with: geographic_scope)
    expect(page).to have_selector("#conditional-corrective_action_related_file_yes a", text: File.basename(file))
    expect(page).to have_field("Attachment description", with: /#{Regexp.escape(file_description)}/)
  end

  def expect_case_activity_page_to_show_entered_data
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: summary).find(:xpath, "..")
    expect(item).to have_text("Legislation: #{legislation}")
    expect(item).to have_text("Date came into effect: #{date.strftime('%d/%m/%Y')}")
    expect(item).to have_text("Type of measure: #{CorrectiveAction.human_attribute_name("measure_type.#{measure_type}")}")
    expect(item).to have_text("Duration of action: #{CorrectiveAction.human_attribute_name("duration.#{duration}")}")
    expect(item).to have_text("Geographic scope: #{geographic_scope}")
    expect(item).to have_text("Attached: #{File.basename(file)}")
    expect(item).to have_text("Geographic scope: #{geographic_scope}")
    expect(item).to have_text(details)
  end

  def expect_case_attachments_page_to_show_file
    expect(page).to have_selector("h1", text: "Attachments")
    expect(page).to have_selector("h2", text: summary)
    expect(page).to have_selector("p", text: file_description)
  end

  def fill_and_submit_form
    fill_in "Summary", with: summary
    fill_in "Day",     with: date.day   if date
    fill_in "Month",   with: date.month if date
    fill_in "Year",    with: date.year  if date
    select legislation, from: "Under which legislation?"
    fill_in "Further details (optional)", with: details
    choose "corrective_action_related_file_yes"
    attach_file "corrective_action[file][file]", file
    fill_in "Attachment description", with: file_description
    choose "corrective_action_measure_type_#{measure_type}"
    choose "corrective_action_duration_#{duration}"
    select geographic_scope, from: "What is the geographic scope of the action?"
    click_button "Continue"
  end
end
