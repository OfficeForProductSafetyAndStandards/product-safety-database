require "rails_helper"

RSpec.feature "Adding a record phone call activity to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, owner: user) }

  let(:name) { "Test name" }
  let(:phone) { "07000 000000" }
  let(:date) { Time.zone.today }
  let(:file) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }
  let(:summary) { "Test summary" }
  let(:notes) { "Test notes" }

  before { sign_in(user) }

  scenario "with consumer contact details and transcript file" do
    visit "/cases/#{investigation.pretty_id}/activity/new"
    expect_to_be_on_new_activity_page

    choose "Record phone call"
    click_button "Continue"

    expect_to_be_on_record_phone_call_page

    # Test required fields
    click_button "Continue"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Correspondence date cannot be blank"

    # Test date validation
    fill_in "Day", with: "333"
    click_button "Continue"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Correspondence date must include a month and year"

    fill_in_record_phone_call_form(name: name, phone: phone, consumer: true, date: date)

    expect_to_be_on_record_phone_call_details_page

    # Test required fields
    click_button "Continue"

    expect(page).to have_error_summary "Please provide either a transcript or complete the summary and notes fields"

    attach_file "correspondence_phone_call[transcript][file]", file
    click_button "Continue"

    expect_to_be_on_confirm_phone_call_details_page
    expect_confirm_phone_call_details_page_to_show_entered_information(name: name, phone: phone, consumer: true, date: date, file: file)

    # Test edit details pages retain entered information
    click_link "Edit details"

    expect_to_be_on_record_phone_call_page
    expect_record_phone_call_form_to_have_entered_information(name: name, phone: phone, consumer: true, date: date)

    click_button "Continue"

    expect_to_be_on_record_phone_call_details_page

    within_fieldset "Details" do
      expect(page).to have_css("a", text: File.basename(file))
    end

    click_button "Continue"

    expect_to_be_on_confirm_phone_call_details_page
    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    # Consumer info is not hidden from case owner
    expect_case_activity_page_to_show_entered_information(name: name, phone: phone, date: date, file: file)

    # Test that another user in a different organisation cannot see consumer info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_restricted_information

    # Test that another user in the same team can see consumer info
    sign_out

    sign_in(other_user_same_team)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(name: name, phone: phone, date: date, file: file)
  end

  scenario "with non-consumer contact details and summary and notes" do
    visit "/cases/#{investigation.pretty_id}/activity/new"
    expect_to_be_on_new_activity_page

    choose "Record phone call"
    click_button "Continue"

    expect_to_be_on_record_phone_call_page
    fill_in_record_phone_call_form(name: name, phone: phone, consumer: false, date: date)

    expect_to_be_on_record_phone_call_details_page

    fill_in_record_phone_call_details_form(summary: summary, notes: notes)
    click_button "Continue"

    expect_to_be_on_confirm_phone_call_details_page
    expect_confirm_phone_call_details_page_to_show_entered_information(name: name, phone: phone, consumer: false, date: date, summary: summary, notes: notes)
    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(name: name, phone: phone, date: date, summary: summary, notes: notes)

    # Test that another user in a different organisation can see all info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(name: name, phone: phone, date: date, summary: summary, notes: notes)
  end

  def fill_in_record_phone_call_form(name:, phone:, consumer:, date:)
    fill_in "Name", with: name if name
    fill_in "Phone number", with: phone if phone

    within_fieldset "Are these consumer contact details?" do
      choose "Yes" if consumer
    end

    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
    click_button "Continue"
  end

  def fill_in_record_phone_call_details_form(summary:, notes:)
    fill_in "Summary", with: summary if summary
    fill_in "Notes", with: notes if notes
  end

  def expect_confirm_phone_call_details_page_to_show_entered_information(name:, phone:, consumer:, date:, file: nil, summary: nil, notes: nil)
    expect(page.find("dt", text: "Call with")).to have_sibling("dd", text: "#{name} (#{phone})")
    expect(page.find("dt", text: "Contains consumer info")).to have_sibling("dd", text: (consumer ? "Yes" : "No"))
    expect(page.find("dt", text: "Date")).to have_sibling("dd", text: date.strftime("%d/%m/%Y"))

    if file
      expect(page.find("dt", text: "Attachments")).to have_sibling("dd", text: File.basename(file))
    else
      expect(page.find("dt", text: "Summary")).to have_sibling("dd", text: summary)
      expect(page.find("dt", text: "Content")).to have_sibling("dd", text: notes)
    end
  end

  def expect_record_phone_call_form_to_have_entered_information(name:, phone:, consumer:, date:)
    expect(find_field("Name").value).to eq name
    expect(find_field("Phone number").value).to eq phone

    checked_option = consumer ? "true" : "false"
    expect(page).to have_checked_field("correspondence_phone_call_has_consumer_info_#{checked_option}")

    expect(find_field("Day").value).to eq date.day.to_s
    expect(find_field("Month").value).to eq date.month.to_s
    expect(find_field("Year").value).to eq date.year.to_s
  end

  def expect_case_activity_page_to_show_entered_information(name:, phone:, date:, file: nil, summary: nil, notes: nil)
    item = page.find("p", text: "Phone call by #{user.name} (#{user.team.name})").find(:xpath, "..")
    expect(item).to have_text("Call with: #{name} (#{phone})")
    expect(item).to have_text("Date: #{date.strftime('%d/%m/%Y')}")

    if file
      expect(item).to have_text("Attached: #{File.basename(file)}")
      expect(item).to have_link("View attachment")
    else
      expect(item).to have_text(summary)
      expect(item).to have_text(notes)
    end
  end

  def expect_case_activity_page_to_show_restricted_information
    item = page.find("h3", text: "Phone call added").find(:xpath, "..")
    expect(item).to have_text("Phone call by #{user.name} (#{user.team.name}), #{Time.zone.today.strftime('%e %B %Y').lstrip}")
    expect(item).to have_text("Restricted access")
    expect(item).to have_text("Consumer contact details hidden to comply with GDPR legislation. Contact #{user.organisation.name}, who created this activity, to obtain these details if required.")
  end
end
