require "rails_helper"

RSpec.feature "Searching cases", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, team:) }

  before do
    sign_in user
  end

  context "when there are no cases" do
    context "when the user is on the your cases page" do
      before do
        click_on "Your cases"
      end

      it "explains that the user has no cases" do
        expect(page).to have_content "You have no open cases."
        expect(highlighted_tab).to eq "Your cases"
      end
    end

    context "when the user is on the team cases page" do
      before do
        click_on "Team cases"
      end

      it "explains that the team has no cases" do
        expect(page).to have_content "The team has no open cases."
        expect(highlighted_tab).to eq "Team cases"
      end
    end

    context "when the user is on the assigned cases page" do
      before do
        click_on "Assigned cases"
      end

      it "explains that the team has no assigned cases" do
        expect(page).to have_content "There are no open cases your team has been added to."
        expect(highlighted_tab).to eq "Assigned cases"
      end
    end
  end

  context "when there are cases" do
    let(:other_user_same_team) { create(:user, :activated, has_viewed_introduction: true, team:) }
    let!(:user_case) { create(:allegation, :with_products, creator: user) }
    let!(:user_case_without_products) { create(:allegation, creator: user) }
    let!(:other_case) { create(:allegation) }
    let!(:team_case) { create(:allegation, creator: other_user_same_team) }

    let(:different_team) { create :team, name: "Different team" }
    let(:different_user) { create :user, :activated, has_viewed_introduction: true, team: different_team }
    let!(:different_team_case) { create(:allegation, creator: different_user) }

    before do
      Investigation.import scope: "not_deleted", refresh: true, force: true
    end

    context "when the user is on the your cases page" do
      before do
        click_on "Your cases"
      end

      it "shows cases that are owned by the user" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: user_case_without_products.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
      end

      it "indicates which cases do not have a product attached" do
        within(sprintf('td[headers="item_investigation_allegation_%{id} status_investigation_allegation_%{id}"]', id: user_case.id)) do
          expect(page).not_to have_content("This case has no product")
        end

        within(sprintf('td[headers="item_investigation_allegation_%{id} status_investigation_allegation_%{id}"]', id: user_case_without_products.id)) do
          expect(page).to have_content("This case has no product")
        end
      end

      context "when less than 12 cases" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 cases" do
        before do
          create_list(:allegation, 11, creator: user)
          Investigation.import scope: "not_deleted", refresh: true, force: true
          visit "/cases/your-cases"
        end

        it "does show the sort filter drop down with 'newest cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest cases")
        end

        it "does not change table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest cases"
          end

          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("#thcreated")
        end
      end
    end

    context "when the user is on the team cases page" do
      it "shows cases that are owned by the users team" do
        click_on "All cases"
        click_on "Team cases"
        expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
      end

      it "indicates which cases do not have a product attached" do
        click_on "All cases"
        click_on "Team cases"
        within(sprintf('td[headers="item_investigation_allegation_%{id} status_investigation_allegation_%{id}"]', id: user_case.id)) do
          expect(page).not_to have_content("This case has no product")
        end

        within(sprintf('td[headers="item_investigation_allegation_%{id} status_investigation_allegation_%{id}"]', id: user_case_without_products.id)) do
          expect(page).to have_content("This case has no product")
        end
      end

      context "when less than 12 cases" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 cases" do
        before do
          create_list(:allegation, 11, creator: other_user_same_team)
          Investigation.import scope: "not_deleted", refresh: true, force: true
          visit "/cases/team-cases"
        end

        it "does show the sort filter drop down with 'newest cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest cases")
        end

        it "does not change table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest cases"
          end

          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")
        end
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
        expect(page).to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
      end

      it "highlights the all cases tab" do
        expect(highlighted_tab).to eq "All cases – Search"
      end

      context "when less than 12 cases" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 cases" do
        before do
          create_list(:allegation, 11)
          Investigation.import scope: "not_deleted", refresh: true, force: true
          visit "/cases/all-cases"
        end

        it "does show the sort filter drop down with 'recent cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Recent updates")
        end

        it "changes table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest cases"
          end

          expect(page).to have_css("th#created")
          expect(page).not_to have_css("th#updated")
        end
      end
    end

    context "when the different team case is assigned to the user's team" do
      before do
        AddTeamToCase.call(user:, investigation: different_team_case, team:, collaboration_class: Collaboration::Access::Edit)
        click_on "All cases"
      end

      context "when on team cases page" do
        before do
          visit "/cases/team-cases"
        end

        it "does not show the case" do
          expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
        end
      end

      context "when on assigned cases page" do
        before do
          visit "/cases/assigned-cases"
        end

        it "shows the case" do
          expect(page).to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
        end
      end

      context "when on all cases page" do
        before do
          visit "/cases/all-cases"
        end

        it "shows the case" do
          expect(page).to have_selector("td.govuk-table__cell", text: different_team_case.pretty_id)
        end
      end
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
