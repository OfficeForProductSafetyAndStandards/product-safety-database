require "rails_helper"

RSpec.feature "Searching cases", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: team }

  before do
    sign_in user
  end

  context "when there are no cases" do
    context "when the user is on the your cases page" do
      before do
        click_on "Your cases"
      end

      it "explains that the user has no cases" do
        expect(page).to have_content "You have no open cases. You can find all other cases in the all cases search page."
      end

      it "highlights the your cases tab" do
        expect(highlighted_tab).to eq "Your cases"
      end
    end

    context "when the user is on the team cases page" do
      before do
        click_on "All cases"
        click_on "Team cases"
      end

      it "explains that the team has no cases" do
        visit "/cases"
        click_on "Team cases"
        expect(page).to have_content "The team has no open cases. You can find all other cases in the all cases search page."
      end

      it "highlights the team cases tab" do
        expect(highlighted_tab).to eq "Team cases"
      end
    end
  end

  context "when there are cases" do
    let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: team }
    let!(:user_case) { create(:allegation, creator: user) }
    let!(:other_case) { create(:allegation) }
    let!(:team_case) { create(:allegation, creator: other_user_same_team) }

    before do
      Investigation.import refresh: true, force: true
    end

    context "when the user is on the your cases page" do
      it "shows cases that are owned by the user" do
        click_on "Your cases"
        expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
      end
    end

    context "when the user is on the team cases page" do
      it "shows cases that are owned by the users team" do
        click_on "All cases"
        click_on "Team cases"
        expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
      end
    end

    context "when the user is on the all cases page" do
      before do
        click_on "All cases"
      end

      it "shows all cases" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
      end

      it "highlights the all cases tab" do
        expect(highlighted_tab).to eq "All cases - Search"
      end
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
