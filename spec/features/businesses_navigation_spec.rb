require "rails_helper"

RSpec.feature "Searching businesses", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: team }

  before do
    sign_in user
    visit "/businesses"
  end

  context "when there are no businesses" do
    context "when the user is on the your businesses page" do
      before do
        click_on "Your businesses"
      end

      it "explains that the user has no businesses" do
        expect(page).to have_content "There are 0 businesses linked to open cases where you are the case owner."
      end

      it "highlights the your businesses tab" do
        expect(highlighted_tab).to eq "Your businesses"
      end
    end

    context "when the user is on the team businesses page" do
      before do
        click_on "All businesses"
        click_on "Team businesses"
      end

      it "explains that the team has no businesses" do
        visit "/businesses"
        click_on "Team businesses"
        expect(page).to have_content "There are 0 businesses linked to open cases where the #{team.name} team is the case owner."
      end

      it "highlights the team businesses tab" do
        expect(highlighted_tab).to eq "Team businesses"
      end
    end
  end

  context "when there are businesses" do
    let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: team }
    let(:user_business) { create(:business, trading_name: "user_business") }
    let(:team_business) { create(:business, trading_name: "team_business") }
    let(:closed_business) { create(:business, trading_name: "closed_business") }
    let(:other_business) { create(:business, trading_name: "other_business") }

    before do
      user_case = create(:allegation, creator: user)
      team_case = create(:allegation, creator: other_user_same_team)
      closed_case = create(:allegation, creator: user, is_closed: true)
      other_case = create(:allegation)

      InvestigationBusiness.create!(business_id: user_business.id, investigation_id: user_case.id)
      InvestigationBusiness.create!(business_id: team_business.id, investigation_id: team_case.id)
      InvestigationBusiness.create!(business_id: closed_business.id, investigation_id: closed_case.id)
      InvestigationBusiness.create!(business_id: other_business.id, investigation_id: other_case.id)

      Investigation.import refresh: true, force: true
      Business.import refresh: true, force: true
    end

    context "when the user is on the your businesses page" do
      before do
        click_on "Your businesses"
      end

      it "shows businesses that are associated with businesses that are owned by the user and open" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
        expect(page).not_to have_selector("td.govuk-table__cell", text: team_business.company_number)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_business.company_number)
      end

      it "does not show closed businesses" do
        expect(page).not_to have_selector("td.govuk-table__cell", text: closed_business.company_number)
      end

      context "when less than 12 businesses" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end
    end

    context "when more than 11 businesses" do
      before do
        11.times do
          create(:allegation, :with_business, creator: user)
          Investigation.import refresh: true, force: true
          Business.import refresh: true, force: true
        end
        visit your_businesses_path
      end

      it "does show the sort filter drop down with 'newly added' sorting option selected" do
        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
      end
    end

    context "when the user is on the team businesses page" do
      it "shows businesses that are owned by the users team" do
        click_on "All businesses"
        click_on "Team businesses"
        expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
        expect(page).to have_selector("td.govuk-table__cell", text: team_business.company_number)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_business.company_number)
      end

      it "does not show closed businesses" do
        expect(page).not_to have_selector("td.govuk-table__cell", text: closed_business.company_number)
      end

      context "when less than 12 businesses" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 businesses" do
        before do
          10.times do
            create(:allegation, :with_business, creator: user)
            Investigation.import refresh: true, force: true
            Business.import refresh: true, force: true
          end
          visit "/businesses/team-businesses"
        end

        it "does show the sort filter drop down with 'newly added' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
        end
      end
    end

    context "when the user is on the all businesses page" do
      before do
        click_on "All businesses"
      end

      it "shows all businesses" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
        expect(page).to have_selector("td.govuk-table__cell", text: team_business.company_number)
        expect(page).to have_selector("td.govuk-table__cell", text: other_business.company_number)
        expect(page).to have_selector("td.govuk-table__cell", text: closed_business.company_number)
      end

      it "highlights the all businesses tab" do
        expect(highlighted_tab).to eq "All businesses - Search"
      end

      it "shows closed businesses" do
        expect(page).to have_selector("td.govuk-table__cell", text: closed_business.company_number)
      end

      context "when less than 12 businesses" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 businesses" do
        before do
          9.times do
            create(:allegation, :with_business, creator: user)
            Investigation.import refresh: true, force: true
            Business.import refresh: true, force: true
          end
          visit "/businesses/all-businesses"
        end

        it "does show the sort filter drop down with 'recent businesses' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
        end
      end
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
