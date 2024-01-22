require "rails_helper"

RSpec.feature "Add case email activity", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:notification) { create(:allegation, creator: user) }

  let(:name) { "Test name" }
  let(:email) { Faker::Internet.email }
  let(:date) { Date.parse("2020-02-01") }

  let(:file) { Rails.root.join("test/fixtures/files/email_file.txt") }

  let(:summary) { "Test summary" }
  let(:email_subject) { "Test subject" }
  let(:body) { "Test body" }
  let(:attachment) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }
  let(:attachment_description) { "Test attachment description" }

  before { sign_in(user) }

  scenario "with email file" do
    visit "/cases/#{notification.pretty_id}"
    click_link "Add a correspondence"

    expect_to_be_on_add_correspondence_page
    expect_to_have_notification_breadcrumbs
    choose "Record email"
    click_button "Continue"

    expect_to_be_on_record_email_page
    expect_to_have_notification_breadcrumbs

    click_button "Add email"
    expect(page).to have_error_summary "Please provide either an email file or a subject and body"
    expect_to_have_notification_breadcrumbs

    within_fieldset "Email content" do
      attach_file "Upload a file", file
    end

    # Test required fields
    click_button "Add email"

    expect(page).to have_error_summary "Enter the date sent"

    within_fieldset "Email content" do
      expect(page).to have_content "Currently selected file: email_file.txt"
    end

    # Test date validation
    fill_in "Day", with: "333"
    click_button "Add email"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Date sent must include a month and year"

    within_fieldset "Email content" do
      expect(page).to have_content "Currently selected file: email_file.txt"
    end

    fill_in_record_email_form(name:, email:, date:)
    fill_in "Summary", with: "Test summary"

    click_button "Add email"

    click_link "Test summary"

    expect_to_be_on_email_page(case_id: notification.pretty_id)
    expect(page).to have_h1("Test summary")
    expect(page).to have_summary_item(key: "Date of email", value: "1 February 2020")
    expect(page).to have_summary_item(key: "From", value: "#{name} (#{email})")
    expect(page).to have_summary_item(key: "Email", value: "email_file.txt (0 Bytes)")

    click_link notification.pretty_id
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)

    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, email:, date:, file:)

    # Test that another user in a different organisation cannot see correspondence
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{notification.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
    expect_case_activity_page_to_show_restricted_information

    # Test that another user in the same team can see correspondence
    sign_out

    sign_in(other_user_same_team)

    visit "/cases/#{notification.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, email:, date:, file:)
  end

  scenario "with summary and subject and body and attachment" do
    visit "/cases/#{notification.pretty_id}"
    click_link "Add a correspondence"

    expect_to_be_on_add_correspondence_page
    expect_to_have_notification_breadcrumbs
    choose "Record email"

    click_button "Continue"
    expect_to_be_on_record_email_page

    # Upload file early to check it persists through validation errors
    within_fieldset "Attachments" do
      attach_file "Upload a file", attachment
      fill_in "Attachment description", with: attachment_description
    end

    click_button "Add email"

    expect_to_have_notification_breadcrumbs
    expect(page).to have_error_messages
    expect(page).to have_error_summary "Enter the date sent"

    fill_in_record_email_form(name:, email:, date:)
    fill_in_record_email_details_form(summary:, subject: email_subject, body:)

    click_button "Add email"

    click_link "Test summary"

    expect_to_be_on_email_page(case_id: notification.pretty_id)
    expect(page).to have_text("attachment_filename.txt")
    expect(page).to have_text("Test attachment description")

    click_link notification.pretty_id
    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
    expect_case_activity_page_to_show_entered_information(user_name: user.name, name:, email:, date:, summary:, subject: email_subject, body:)

    # Test that another user in a different organisation cannot see correspondence
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{notification.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
    expect_case_activity_page_to_show_restricted_information
  end

  def fill_in_record_email_form(name:, email:, date:)
    choose "From"

    fill_in "Name", with: name if name
    fill_in "Email address", with: email if email

    fill_in "Day",   with: date.day if date
    fill_in "Month", with: date.month if date
    fill_in "Year",  with: date.year  if date
  end

  def fill_in_record_email_details_form(summary:, subject:, body:)
    fill_in "Summary", with: summary if summary
    fill_in "Subject line", with: subject if subject
    fill_in "Body", with: body if body
  end

  def expect_confirm_email_details_page_to_show_entered_information(email:, date:, file: nil, summary: nil, subject: nil, body: nil)
    expect(page).to have_summary_table_item(key: "From", value: email)
    expect(page).to have_summary_table_item(key: "Date sent", value: date.strftime("%d/%m/%Y"))

    if file
      expect(page).to have_summary_table_item(key: "Email", value: File.basename(file))
    else
      expect(page).to have_summary_table_item(key: "Summary", value: summary)
      expect(page).to have_summary_table_item(key: "Subject", value: subject)
      expect(page).to have_summary_table_item(key: "Content", value: body)
    end
  end

  def expect_record_email_form_to_have_entered_information(name:, email:, date:)
    expect(page).to have_checked_field("correspondence_email_email_direction_inbound")

    expect(find_field("Name").value).to eq name
    expect(find_field("Email").value).to eq email
    expect(find_field("Day").value).to eq date.day.to_s
    expect(find_field("Month").value).to eq date.month.to_s
    expect(find_field("Year").value).to eq date.year.to_s
  end

  def expect_case_activity_page_to_show_entered_information(user_name:, name:, email:, date:, file: nil, summary: nil, subject: nil, body: nil)
    item = page.find("p", text: "Email recorded by #{user_name}").find(:xpath, "..")
    expect(item).to have_text("Email address: #{email}")
    expect(item).to have_text("Contact: #{name}")
    expect(item).to have_text("Date of email: #{date.to_formatted_s(:govuk)}")

    if file
      expect(item).to have_text("Email: #{File.basename(file)}")
      expect(item).to have_link("View email")
    else
      expect(item).to have_text(summary)
      expect(item).to have_text(subject)
      expect(item).to have_text(body)
    end
  end

  def expect_case_activity_page_to_show_restricted_information
    item = page.find("h3", text: "Email added").find(:xpath, "..")
    expect(item).to have_text("Email recorded by #{user.name} (#{user.team.name}), #{Time.zone.today.strftime('%e %B %Y').lstrip}")
    expect(item).to have_text("Only teams added to the notification can view correspondence")
  end
end
