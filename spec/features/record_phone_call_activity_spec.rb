require "rails_helper"

RSpec.feature "Adding a record phone call activity to a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, creator: user) }

  let(:name) { "Test name" }
  let(:phone) { "07000 000000" }
  let(:date) { Date.parse("2020-05-05") }
  let(:file) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }
  let(:summary) { "Test summary" }
  let(:notes) { "Test notes" }

  before { sign_in(user) }

  scenario "with transcript file" do
    visit "/cases/#{investigation.pretty_id}"
    click_link "Add a correspondence"

    expect_to_be_on_add_correspondence_page
    expect_to_have_notification_breadcrumbs
    choose "Record phone call"
    click_button "Continue"

    expect_to_be_on_record_phone_call_page
    expect_to_have_notification_breadcrumbs

    # Test required fields
    click_button "Add phone call"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Enter the date of call"
    expect_to_have_notification_breadcrumbs

    # Test date validation
    fill_in "Day", with: "333"
    click_on "Add phone call"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Date of call must include a month and year"

    future_date = 1.day.from_now
    fill_in "Day", with: future_date.day
    fill_in "Month", with: future_date.month
    fill_in "Year", with: future_date.year
    click_on "Add phone call"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Date of call must be today or in the past"
    # End test date validation

    fill_in_record_phone_call_form(name:, phone:, date:)

    expect_to_be_on_record_phone_call_details_page
    expect_to_have_notification_breadcrumbs

    # Test required fields
    click_button "Add phone call"

    expect(page).to have_error_summary "Please provide either a transcript or complete the summary and notes fields"

    attach_file "Upload a file", file
    click_button "Add phone call"

    click_link "Phone call on 5 May 2020"

    expect_to_be_on_phone_call_page(case_id: investigation.pretty_id)
    expect_to_have_notification_breadcrumbs

    click_on investigation.pretty_id
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, phone:, date:, file:)

    click_link "View phone call"

    expect_to_be_on_phone_call_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Date of call", value: "5 May 2020")
    expect(page).to have_summary_item(key: "Call with", value: "#{name} (#{phone})")
    expect(page).to have_summary_item(key: "Transcript", value: "attachment_filename.txt (15 Bytes)")

    # Test that another user in a different organisation cannot see correspondence info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_restricted_information

    # Test that another user in the same team can see correspondence
    sign_out

    sign_in(other_user_same_team)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, phone:, date:, file:)
  end

  scenario "with summary and notes" do
    visit "/cases/#{investigation.pretty_id}"
    click_link "Add a correspondence"

    expect_to_be_on_add_correspondence_page
    choose "Record phone call"
    click_button "Continue"

    expect_to_be_on_record_phone_call_page
    fill_in_record_phone_call_form(name:, phone:, date:)

    expect_to_be_on_record_phone_call_details_page

    fill_in_record_phone_call_details_form(summary:, notes:)
    click_button "Add phone call"

    click_link "Test summary"
    expect_to_have_notification_breadcrumbs

    click_on investigation.pretty_id
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, phone:, date:, summary:, notes:)

    # Test that another user in a different organisation cannot see correspondence info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_restricted_information
  end

  def fill_in_record_phone_call_form(name:, phone:, date:)
    fill_in "Name", with: name if name
    fill_in "Phone number", with: phone if phone

    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
  end

  def fill_in_record_phone_call_details_form(summary:, notes:)
    fill_in "Summary", with: summary if summary
    fill_in "Notes", with: notes if notes
  end

  def expect_record_phone_call_form_to_have_entered_information(name:, phone:, date:)
    expect(find_field("Name").value).to eq name
    expect(find_field("Phone number").value).to eq phone
    expect(find_field("Day").value).to eq date.day.to_s
    expect(find_field("Month").value).to eq date.month.to_s
    expect(find_field("Year").value).to eq date.year.to_s
  end

  def expect_case_activity_page_to_show_entered_information(user_name:, name:, phone:, date:, file: nil, summary: nil, notes: nil)
    item = page.find("p", text: "Phone call by #{user_name}").find(:xpath, "..")
    expect(item).to have_text("Call with: #{name} (#{phone})")
    expect(item).to have_text("Date: #{date.to_formatted_s(:govuk)}")

    if file
      expect(item).to have_text("Attached: #{File.basename(file)}")
      expect(item).to have_link("View phone call")
    else
      expect(item).to have_text(summary)
      expect(item).to have_text(notes)
    end
  end

  def expect_case_activity_page_to_show_restricted_information
    item = page.find("h3", text: "Phone call added").find(:xpath, "..")
    expect(item).to have_text("Phone call by #{user.name} (#{user.team.name}), #{Time.zone.today.strftime('%e %B %Y').lstrip}")
    expect(item).to have_text("Only teams added to the notification can view correspondence")
  end
end
