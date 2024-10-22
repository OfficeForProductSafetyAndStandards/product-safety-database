require "rails_helper"

RSpec.feature "Searching businesses", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: }

  let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: }
  let(:user_business) { create(:business, trading_name: "user_business", legal_name: "user_business Ltd") }
  let(:team_business) { create(:business, trading_name: "team_business", legal_name: "team_business Ltd") }
  let(:closed_business) { create(:business, trading_name: "closed_business", legal_name: "closed_business Ltd") }
  let(:other_business) { create(:business, trading_name: "other_business", legal_name: "other_business Ltd") }

  def create_four_businesses!
    user_case = create(:allegation, creator: user)
    team_case = create(:allegation, creator: other_user_same_team)
    closed_case = create(:allegation, creator: user, is_closed: true)
    other_case = create(:allegation)

    InvestigationBusiness.create!(business_id: user_business.id, investigation_id: user_case.id)
    InvestigationBusiness.create!(business_id: team_business.id, investigation_id: team_case.id)
    InvestigationBusiness.create!(business_id: closed_business.id, investigation_id: closed_case.id)
    InvestigationBusiness.create!(business_id: other_business.id, investigation_id: other_case.id)

    Investigation.reindex
  end

  scenario "No businesses" do
    sign_in(user)
    visit "/businesses"

    click_on "Team businesses"

    expect(highlighted_tab).to eq "Team businesses"
    expect(page).to have_content "There are 0 businesses linked to open notifications where the #{team.name} team is the notification owner."

    click_on "Your businesses"

    expect(highlighted_tab).to eq "Your businesses"
    expect(page).to have_content "There are 0 businesses linked to open notifications where you are the notification owner."
  end

  scenario "Browsing businesses" do
    create_four_businesses!

    sign_in(user)
    visit "/businesses"

    expect(highlighted_tab).to eq "All businesses - Search"
    expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
    expect(page).to have_selector("td.govuk-table__cell", text: team_business.company_number)
    expect(page).to have_selector("td.govuk-table__cell", text: other_business.company_number)
    expect(page).to have_selector("td.govuk-table__cell", text: closed_business.company_number)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    click_on "Team businesses"

    expect(highlighted_tab).to eq "Team businesses"
    expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
    expect(page).to have_selector("td.govuk-table__cell", text: team_business.company_number)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_business.company_number)
    expect(page).not_to have_selector("td.govuk-table__cell", text: closed_business.company_number)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    click_on "Your businesses"

    expect(highlighted_tab).to eq "Your businesses"
    expect(page).to have_selector("td.govuk-table__cell", text: user_business.company_number)
    expect(page).not_to have_selector("td.govuk-table__cell", text: team_business.company_number)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_business.company_number)
    expect(page).not_to have_selector("td.govuk-table__cell", text: closed_business.company_number)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    # Add more businesses and reload page
    create_list(:business, 8)

    visit "/businesses"
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added") # sort filter drop down
  end

  scenario "Business table is displayed with columns" do
    create_four_businesses!

    sign_in(user)
    visit "/businesses"

    expect(highlighted_tab).to eq "All businesses - Search"

    within "table > thead" do
      expect(page).to have_text("Trading name")
      expect(page).to have_text("Registered or Legal name")
      expect(page).to have_text("Company number")
    end

    within "table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)" do
      expect(page).to have_link(other_business.trading_name, href: business_path(other_business))
    end

    within "table tbody.govuk-table__body > tr:nth-child(1)" do
      expect(page).to have_text(other_business.legal_name)
      expect(page).to have_text(other_business.company_number)
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
