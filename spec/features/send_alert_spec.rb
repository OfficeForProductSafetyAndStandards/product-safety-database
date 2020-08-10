require "rails_helper"

RSpec.feature "Sending a product safety alert", :with_stubbed_elasticsearch, :with_test_queue_adapter, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :opss_user, email: "user@example.com") }
  let(:investigation) { create(:allegation, creator: user) }

  let(:restricted_investigation) { create(:allegation, :restricted, creator: user) }

  before do
    create(:user, :activated, email: "jason@example.com")
    create(:user, :inactive)
    sign_in(user)

    # Don't need to generate preview for these tests. govuk_notify_rails throws an exception of no valid Notify key provided
    allow(Notifications::Client).to receive(:new).and_return(nil)
    allow(NotificationsClient.instance).to receive(:generate_template_preview).and_return(OpenStruct.new(html: nil))
  end

  scenario "Sending an alert about a case to 2 active users" do
    visit investigation_path(investigation)

    click_link "Actions"
    expect_to_be_on_case_actions_page(case_id: investigation.pretty_id)

    within_fieldset "Select an action" do
      choose "Send email alert"
    end
    click_button "Continue"

    click_link "Compose new alert"

    expect_to_be_on_compose_alert_for_case_page(case_id: investigation.pretty_id)

    # Check that the 2 fields are pre-filled with the default values
    expect(find_field("Alert subject").value).to eq("Product safety alert: ")
    expect(find_field("Alert summary").value).to include("More details can be found on the case page: http://www.example.com/cases/#{investigation.pretty_id}")

    fill_in "Alert subject", with: "Important safety alert"
    fill_in "Alert summary", with: "Please review this case"

    click_button "Preview alert"

    expect(page.text).to match(/All users \(\d+ people\)/)
    expect(page.text.match(/All users \((\d+) people\)/).captures.first).to eq("2")

    click_link "edit your message"

    expect_to_be_on_compose_alert_for_case_page(case_id: investigation.pretty_id)

    expect(page).to have_field("Alert subject", with: "Important safety alert")
    expect(page).to have_field("Alert summary", text: "Please review this case")

    fill_in "Alert summary", with: "Please review this case urgently!"

    click_button "Preview alert"

    perform_enqueued_jobs do
      click_button "Send to 2 people"

      expect_to_be_on_case_page(case_id: investigation.pretty_id)
      expect(page).to have_text("Email alert sent to 2 users")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

      expect(page).to have_text("Product safety alert sent")
      expect(page).to have_text("Subject: Important safety alert")
      expect(page).to have_text("Please review this case urgently!")

      expect(delivered_emails.size).to eq 2

      recipients = delivered_emails.collect(&:recipient)
      expect(recipients.sort).to eq(["jason@example.com", "user@example.com"])

      email_subjects = delivered_emails.collect { |email| email.personalization[:subject_text] }
      expect(email_subjects.uniq).to eq(["Important safety alert"])

      email_texts = delivered_emails.collect { |email| email.personalization[:email_text] }
      expect(email_texts.uniq).to eq(["Please review this case urgently!"])
    end
  end

  scenario "Being unable to send an alert about a restricted case" do
    visit investigation_path(restricted_investigation)

    click_link "Actions"
    expect_to_be_on_case_actions_page(case_id: restricted_investigation.pretty_id)

    within_fieldset "Select an action" do
      choose "Send email alert"
    end
    click_button "Continue"

    expect_to_be_on_about_alerts_page(case_id: restricted_investigation.pretty_id)
    expect(page).to have_text("Email alerts can only be sent for cases that are not restricted. To send an alert about this case you need to unrestrict it.")

    click_link "Change case visibility"
    expect_to_be_on_case_visiblity_page(case_id: restricted_investigation.pretty_id)
  end
end
