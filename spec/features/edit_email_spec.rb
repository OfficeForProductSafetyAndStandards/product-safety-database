require "rails_helper"

RSpec.feature "Editing an email associated with a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, creator: user) }

  let(:attachment_file_path) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }
  let(:attachment) { Rack::Test::UploadedFile.new(attachment_file_path) }

  let(:replacement_file) { Rails.root.join("spec/fixtures/files/email_attachment.txt") }

  let(:email) do
    create(
      :email,
      investigation:,
      correspondence_date: Date.new(2020, 3, 4),
      correspondent_name: "Bob Jones",
      email_direction: :outbound,
      email_address: "name@example.com",
      email_file: nil,
      email_subject: "Re: safety of product",
      details: "Please see attachment.",
      email_attachment: attachment,
      overview: ""
    )
  end

  before do
    email.email_attachment.blob.metadata[:description] = "Safety document"
    email.email_attachment.blob.save!

    sign_in(user)
  end

  scenario "Editing an email" do
    visit "/cases/#{investigation.pretty_id}/emails/#{email.id}"

    click_link "Edit email"
    expect_to_be_on_edit_email_page(case_id: investigation.pretty_id, email_id: email.id)
    expect_to_have_notification_breadcrumbs

    # Check that form is pre-filled with existing values
    expect_to_be_on_edit_email_page(case_id: investigation.pretty_id, email_id: email.id)

    within_fieldset "Email details" do
      expect(page).to have_checked_field("To")
      expect(page).to have_field("Name", with: "Bob Jones")
      expect(page).to have_field("Email address", with: "name@example.com")
    end

    within_fieldset "Date sent" do
      expect(page).to have_field("Day", with: "4")
      expect(page).to have_field("Month", with: "3")
      expect(page).to have_field("Year", with: "2020")
    end

    expect(page).to have_field("Summary", with: "")

    within_fieldset "Email content" do
      expect(page).to have_field("Subject line", with: "Re: safety of product")
      expect(page).to have_field("Body", text: "Please see attachment.")
    end

    within_fieldset "Attachments" do
      expect(page).to have_text("Currently attached file: attachment_filename.txt")
      expect(page).to have_field("Attachment description", text: "Safety document")

      within_fieldset "Replace or remove email attachment" do
        expect(page).to have_checked_field("Keep file")
      end
    end

    # Change some values to introduce a validation error
    within_fieldset "Date sent" do
      fill_in "Day", with: "32"
    end

    # Also select a replacement attachment file and attachment description
    within_fieldset "Attachments" do
      within_fieldset "Replace or remove email attachment" do
        choose "Upload a replacement file"
        attach_file "Upload a file", replacement_file
      end

      fill_in "Attachment description", with: "Manufacturer safety document"
    end

    click_button "Update email"
    expect_to_have_notification_breadcrumbs
    expect(page).to have_text("Date sent must be a real date")

    # Field should retain invalid value
    within_fieldset "Date sent" do
      expect(page).to have_field("Day", with: "32")
    end

    # Attachments radio should still be selected as "Upload a replacement file"
    # but contain a link to the previous-uploaded replacement file
    within_fieldset "Attachments" do
      within_fieldset "Replace or remove email attachment" do
        expect(page).to have_checked_field("Upload a replacement file")
        expect(page).to have_text("email_attachment.txt")
      end
    end

    # Fix the validation error
    within_fieldset "Date sent" do
      fill_in "Day", with: "02"
      fill_in "Month", with: "4 "
    end

    # Also update another field
    fill_in "Summary", with: "Note received from manufacturer"

    click_button "Update email"

    click_link "Note received from manufacturer"

    expect_to_be_on_email_page(case_id: investigation.pretty_id, email_id: email.id)

    # Page should show updated details
    expect(page).to have_summary_item(key: "Date of email", value: "2 April 2020")

    expect(page).to have_h1("Note received from manufacturer")

    expect(page).to have_text("email_attachment.txt")
    expect(page).to have_text("Manufacturer safety document")

    # Test that another user in a different organisation cannot see correspondence activity
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"
    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_text("Email updated by #{user.name}")
    expect(page).to have_text("Only teams added to the notification can view correspondence")
  end

  scenario "Removing attachment from an email" do
    visit "/cases/#{investigation.pretty_id}/emails/#{email.id}"

    click_link "Edit email"
    expect_to_be_on_edit_email_page(case_id: investigation.pretty_id, email_id: email.id)

    within_fieldset "Attachments" do
      within_fieldset "Replace or remove email attachment" do
        choose "Remove file"
      end
    end

    click_button "Update email"
    click_link "Email on 4 March 2020"
    expect_to_be_on_email_page(case_id: investigation.pretty_id, email_id: email.id)
    expect_to_have_notification_breadcrumbs

    expect(page).not_to have_text("attachment_filename.txt")
  end
end
