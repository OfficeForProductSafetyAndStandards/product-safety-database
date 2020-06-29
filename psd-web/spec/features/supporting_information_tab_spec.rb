require "rails_helper"

RSpec.feature "Manage supporting information", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, :with_document, owner: user.team) }

  include_context "with all types of supporting information"

  context "when the team from the user viewing the information owns the investigation" do
    before { sign_in user }

    scenario "listing supporting information" do
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
        expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: test_result.date_added)
      end

      select "Title", from: "sort_by"
      click_on "Sort"
      within page.first("table") do
        sorted_titles = find_all("tr.govuk-table__row td.govuk-table__cell a").map(&:text)
        expected_titles = ["Corrective action", "Email correspondence", "Meeting correspondence", "Passed test: product name", "Phone call correspondence"]
        expect(sorted_titles).to eq expected_titles
      end
    end
  end

  context "when the user does not belong to any of the teams with access to the investigation" do
    let(:other_user) { create(:user, :activated, has_viewed_introduction: true) }

    before { sign_in other_user }

    scenario "viewing the supporting information tab displays restricted information for the generic attachments" do
      visit "/cases/#{investigation.pretty_id}"
      click_link "Supporting information"
      expect(page).not_to have_css("h2", text: investigation.documents.first.title)
      expect(page).to have_css("h2", text: "Attachment")
      expect(page).to have_css("p", text: "Only teams added to the case can view these files")
    end
  end
end
