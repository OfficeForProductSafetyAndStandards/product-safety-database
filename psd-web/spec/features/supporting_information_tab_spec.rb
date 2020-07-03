require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations
RSpec.feature "Manage supporting information", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:read_only_team) { create(:team) }
  let(:read_only_user) { create(:user, :activated, has_viewed_introduction: true, team: read_only_team) }
  let(:user)           { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation)  { create(:allegation, :with_document, creator: user, read_only_teams: read_only_team) }

  include_context "with all types of supporting information"

  context "when the team from the user viewing the information owns the investigation" do
    scenario "listing supporting information" do
      sign_in read_only_user

      visit "/cases/#{investigation.pretty_id}"

      click_on "Supporting information (6)"

      expect_to_view_supporting_information_table

      sign_out

      sign_in user

      visit "/cases/#{investigation.pretty_id}"

      click_on "Supporting information (6)"

      expect_to_view_supporting_information_table

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
# rubocop:enable RSpec/MultipleExpectations
