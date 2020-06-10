require "rails_helper"

RSpec.feature "Supporting information", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with all types of supporting information"

  let(:user)                       { create(:user) }
  let(:investigation)              { create(:allegation, :with_antivirus_checked_document).decorate }

  before { sign_in create(:user, :activated, has_viewed_introduction: true) }

  scenario "listing supporting information" do # rubocop:disable Rails/MultipleExpectations
    visit "/cases/#{investigation.pretty_id}"

    click_on "Supporting information (6)"

    within page.first("table") do
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: email.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondenceEmail")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: email.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: phone_call.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondencePhone call")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: phone_call.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: meeting.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: "CorrespondenceMeeting")
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: meeting.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: corrective_action.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.supporting_information_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: corrective_action.date_added)

      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell a", text: test_result.supporting_information_title)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.supporting_information_type)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_of_activity)
      expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_added)

      expect(page).not_to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_request.supporting_information_title)
    end
  end
end
