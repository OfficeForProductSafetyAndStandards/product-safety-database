require "rails_helper"

RSpec.feature "Supporting information", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with all types of supporting information"

  let(:user)                       { create(:user) }
  let(:investigation)              { create(:allegation, :with_antivirus_checked_document).decorate }
  let(:email_file)                 { email.email_file.decorate }
  let(:phone_call_transcript)      { phone_call.transcript.decorate }
  let(:meeting_transcript)         { meetting.transcript.decorate }
  let(:corrective_action_document) { corrective_action.document.first.decorate  }

  before { sign_in create(:user, :activated, has_viewed_introduction: true) }

  scenario "listing supporting information" do
    visit "/cases/#{investigation.pretty_id}"

    click_on "Supporting information (7)"

    within page.first("table") do
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.record_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.date_added)
      # expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell govuk-caption-m", text: "by anonymous")

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call_transcript.title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call_transcript.record_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call_transcript.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call_transcript.date_added)
      # expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell govuk-caption-m", text: "anonymous")

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting_transcript.title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting_transcript.record_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting_transcript.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting_transcript.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action_document.title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.table_display_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action_document.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action_document.date_added)
    end
  end
end
