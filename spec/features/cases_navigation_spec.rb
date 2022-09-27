require "rails_helper"

RSpec.feature "Searching cases", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: }

  let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: }

  scenario "No cases" do
    sign_in user

    click_on "Your cases"

    expect(highlighted_tab).to eq "Your cases"
    expect(page).to have_content "You have no open cases. You can find all other cases in the all cases search page."

    click_on "Team cases"

    expect(highlighted_tab).to eq "Team cases"
    expect(page).to have_content "The team has no open cases. You can find all other cases in the all cases search page."
  end

  scenario "Browsing cases" do
    user_case = create(:allegation, creator: user)
    other_case = create(:allegation)
    team_case = create(:allegation, creator: other_user_same_team)
    Investigation.import refresh: true, force: true

    sign_in user

    click_on "All cases"

    expect(highlighted_tab).to eq "All cases – Search"
    expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
    expect(page).to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
    expect(page).to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
    expect(page).not_to have_css("form dl.opss-dl-select dd")  # sort filter drop down

    click_on "Your cases"

    expect(highlighted_tab).to eq "Your cases"
    expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
    expect(page).not_to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
    expect(page).not_to have_css("form dl.opss-dl-select dd")  # sort filter drop down

    click_on "Team cases"

    expect(highlighted_tab).to eq "Team cases"
    expect(page).to have_selector("td.govuk-table__cell", text: user_case.pretty_id)
    expect(page).to have_selector("td.govuk-table__cell", text: team_case.pretty_id)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_case.pretty_id)
    expect(page).not_to have_css("form dl.opss-dl-select dd")  # sort filter drop down

    # Add more cases and reload page
    create_list(:allegation, 11, creator: user)
    Investigation.import refresh: true, force: true
    visit "/cases/your-cases"

    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest cases") # sort filter drop down

    # does not change table headers when user changes the filter options
    expect(page).to have_css("th#updated")
    expect(page).not_to have_css("th#created")

    within("form dl.govuk-list.opss-dl-select") { click_on "Oldest cases" }

    expect(page).to have_css("th#updated")
    expect(page).not_to have_css("#thcreated")
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
