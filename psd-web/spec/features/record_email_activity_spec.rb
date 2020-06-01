require "rails_helper"

RSpec.feature "Adding a record email activity to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, owner: user) }

  let(:name) { "Test name" }
  let(:email) { Faker::Internet.safe_email }
  let(:date) { Time.zone.today }

  let(:file) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }
  let(:summary) { "Test summary" }
  let(:email_subject) { "Test subject" }
  let(:body) { "Test body" }

  before { sign_in(user) }

  scenario "with consumer contact details and email file" do
    visit "/cases/#{investigation.pretty_id}/activity/new"
    expect_to_be_on_new_activity_page

    choose "Record email"
    click_button "Continue"

    expect_to_be_on_record_email_page

    # Test required fields
    click_button "Continue"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Correspondence date cannot be blank"

    # Test date validation
    fill_in "Day", with: "333"
    click_button "Continue"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Correspondence date must include a month and year"

    fill_in_record_email_form(name: name, email: email, consumer: true, date: date)

    expect_to_be_on_record_email_details_page

    # Test required fields
    click_button "Continue"

    expect(page).to have_error_summary "Please provide either an email file or a subject and body"

    attach_file "correspondence_email[email_file][file]", file
    click_button "Continue"

    expect_to_be_on_confirm_email_details_page
    expect_confirm_email_details_page_to_show_entered_information(email: email, consumer: true, date: date, file: file)

    # Test edit details pages retain entered information
    click_link "Edit details"

    expect_to_be_on_record_email_page
    expect_record_email_form_to_have_entered_information(name: name, email: email, consumer: true, date: date)

    click_button "Continue"

    expect_to_be_on_record_email_details_page

    within_fieldset "Email content" do
      expect(page).to have_css("a", text: File.basename(file))
    end

    click_button "Continue"

    expect_to_be_on_confirm_email_details_page
    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    # Consumer info is not hidden from case owner
    expect_case_activity_page_to_show_entered_information(name: name, email: email, date: date, file: file)

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
    expect_case_activity_page_to_show_entered_information(name: name, email: email, date: date, file: file)
  end

  scenario "with non-consumer contact details and summary and subject and body" do
    visit "/cases/#{investigation.pretty_id}/activity/new"
    expect_to_be_on_new_activity_page

    choose "Record email"
    click_button "Continue"

    expect_to_be_on_record_email_page
    fill_in_record_email_form(name: name, email: email, consumer: false, date: date)

    expect_to_be_on_record_email_details_page

    fill_in_record_email_details_form(summary: summary, subject: email_subject, body: body)
    click_button "Continue"

    expect_to_be_on_confirm_email_details_page
    expect_confirm_email_details_page_to_show_entered_information(email: email, consumer: false, date: date, summary: summary, subject: email_subject, body: body)
    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(name: name, email: email, date: date, summary: summary, subject: email_subject, body: body)

    # Test that another user in a different organisation can see all info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_entered_information(name: name, email: email, date: date, summary: summary, subject: email_subject, body: body)
  end

  def fill_in_record_email_form(name:, email:, consumer:, date:)
    choose "From"

    fill_in "Name", with: name if name
    fill_in "Email address", with: email if email

    within_fieldset "Are these consumer contact details?" do
      choose "Yes" if consumer
    end

    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
    click_button "Continue"
  end

  def fill_in_record_email_details_form(summary:, subject:, body:)
    fill_in "Summary", with: summary if summary
    fill_in "Subject line", with: subject if subject
    fill_in "Body", with: body if body
  end

  def expect_confirm_email_details_page_to_show_entered_information(email:, consumer:, date:, file: nil, summary: nil, subject: nil, body: nil)
    expect(page).to have_summary_table_item(key: "From", value: email)
    expect(page).to have_summary_table_item(key: "Contains consumer info", value: (consumer ? "Yes" : "No"))
    expect(page).to have_summary_table_item(key: "Date sent", value: date.strftime("%d/%m/%Y"))

    if file
      expect(page).to have_summary_table_item(key: "Email", value: File.basename(file))
    else
      expect(page).to have_summary_table_item(key: "Summary", value: summary)
      expect(page).to have_summary_table_item(key: "Subject", value: subject)
      expect(page).to have_summary_table_item(key: "Content", value: body)
    end
  end

  def expect_record_email_form_to_have_entered_information(name:, email:, consumer:, date:)
    expect(page).to have_checked_field("correspondence_email_email_direction_inbound")

    expect(find_field("Name").value).to eq name
    expect(find_field("Email").value).to eq email

    checked_option = consumer ? "true" : "false"
    expect(page).to have_checked_field("correspondence_email_has_consumer_info_#{checked_option}")

    expect(find_field("Day").value).to eq date.day.to_s
    expect(find_field("Month").value).to eq date.month.to_s
    expect(find_field("Year").value).to eq date.year.to_s
  end

  def expect_case_activity_page_to_show_entered_information(name:, email:, date:, file: nil, summary: nil, subject: nil, body: nil)
    item = page.find("p", text: "Email recorded by #{user.name} (#{user.team.name})").find(:xpath, "..")
    expect(item).to have_text("From: #{name} (#{email})")
    expect(item).to have_text("Date sent: #{date.strftime('%d/%m/%Y')}")

    if file
      expect(item).to have_text("Email: #{File.basename(file)}")
      expect(item).to have_link("View email file")
    else
      expect(item).to have_text(summary)
      expect(item).to have_text(subject)
      expect(item).to have_text(body)
    end
  end

  def expect_case_activity_page_to_show_restricted_information
    item = page.find("h3", text: "Email added").find(:xpath, "..")
    expect(item).to have_text("Email recorded by #{user.name} (#{user.team.name}), #{Time.zone.today.strftime('%e %B %Y').lstrip}")
    expect(item).to have_text("Restricted access")
    expect(item).to have_text("Consumer contact details hidden to comply with GDPR legislation. Contact #{user.organisation.name}, who created this activity, to obtain these details if required.")
  end
end
