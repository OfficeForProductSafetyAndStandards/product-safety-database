require "rails_helper"

RSpec.feature "Supporting information", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:user) { create(:user) }
  let(:investigation) { create(:allegation, :with_antivirus_checked_document).decorate }

  include_context "with all types of supporting information"
  let(:email_file) { email.email_file.decorate }
  before { sign_in create(:user, :activated, has_viewed_introduction: true) }

  scenario "listing supporting information" do
    visit "/cases/#{investigation.pretty_id}"

    click_on "Supporting information (7)"

    within page.first("table") do
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email.class.model_name.human)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email_file.date_added)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell govuk-caption-m", text: "anonimous")

      # expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call.transcript.decorate.title)
    end
  end
end
