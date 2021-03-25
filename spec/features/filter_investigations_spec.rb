require "rails_helper"

RSpec.feature "Case filtering", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:other_organisation) { create(:organisation) }

  let(:organisation)          { create(:organisation) }
  let(:team)                  { create(:team, organisation: organisation) }
  let(:other_team)            { create(:team, organisation: organisation, name: "other team") }
  let(:user)                  { create(:user, :activated, organisation: organisation, team: team, has_viewed_introduction: true) }
  let(:other_user_same_team)  { create(:user, :activated, name: "other user same team", organisation: organisation, team: team) }
  let(:other_user_other_team) { create(:user, :activated, name: "other user other team", organisation: organisation, team: other_team) }

  let!(:investigation)                       { create(:allegation, creator: user) }
  let!(:other_user_investigation)            { create(:allegation, creator: other_user_same_team) }
  let!(:other_user_other_team_investigation) { create(:allegation, creator: other_user_other_team) }
  let!(:other_team_investigation)            { create(:allegation, creator: other_user_other_team) }
  let!(:another_team_investigation)          { create(:allegation, creator: create(:user)) }

  let!(:closed_investigation) { create(:allegation, :closed) }
  let!(:project) { create(:project) }
  let!(:enquiry) { create(:enquiry) }

  let!(:coronavirus_investigation)        { create(:allegation, creator: user, coronavirus_related: true) }
  let!(:serious_risk_level_investigation) { create(:allegation, creator: user, risk_level: Investigation.risk_levels[:serious]) }
  let!(:high_risk_level_investigation)    { create(:allegation, creator: user, risk_level: Investigation.risk_levels[:high]) }

  let!(:another_active_user)   { create(:user, :activated, organisation: user.organisation, team: team) }
  let!(:another_inactive_user) { create(:user, :inactive,  organisation: user.organisation, team: team) }
  let!(:other_deleted_team)    { create(:team, :deleted) }

  let(:restricted_case_title) { "Restricted case title" }
  let(:restricted_case_team) { create(:team, organisation: other_organisation) }
  let(:restricted_case_team_user) { create(:user, team: restricted_case_team, organisation: other_organisation) }
  let!(:restricted_case) { create(:allegation, creator: restricted_case_team_user, is_private: true, description: restricted_case_title).decorate }

  before do
    other_team_investigation.touch # Tests sort order
    Investigation.import refresh: :wait_for
    sign_in(user)
    visit investigations_path
  end

  scenario "filter investigations created by another team" do
    within_fieldset("Created by") do
      check "Other person or team"
      select other_team.name, from: "Name"
    end
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "selecting filters only shows other active users and teams in the case owner and created by filters" do
    within_fieldset("Case owner") do
      expect(page).to have_select("Name", with_options: [team.name, other_team.name, another_active_user.name])
      expect(page).not_to have_select("Name", with_options: [another_inactive_user.name, other_deleted_team.name])
    end

    within_fieldset("Created by") do
      expect(page).to have_select("Name", with_options: [team.name, other_team.name, another_active_user.name])
      expect(page).not_to have_select("Name", with_options: [another_inactive_user.name, other_deleted_team.name])
    end
  end

  scenario "no filters applied shows all open cases" do
    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)

    expect(page).not_to have_listed_case(closed_investigation.pretty_id)

    within_fieldset "Status" do
      expect(page).to have_checked_field("Open")
      expect(page).to have_unchecked_field("Closed")
    end

    within_fieldset "Sort by" do
      expect(page).to have_checked_field("Most recently updated")
    end
  end

  scenario "filtering for both open and closed cases" do
    within_fieldset("Status") { check "Closed" }
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(closed_investigation.pretty_id)
  end

  scenario "filtering only closed cases" do
    within_fieldset "Status" do
      uncheck "Open"
      check "Closed"
    end
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(closed_investigation.pretty_id)
  end

  scenario "filtering for projects and enquiries" do
    within_fieldset "Type" do
      uncheck "Allegation"
      check "Enquiry"
      check "Project"
    end
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(project.pretty_id)
    expect(page).to have_listed_case(enquiry.pretty_id)
  end

  scenario "filtering cases where the user is the owner" do
    check "Me", id: "case_owner_is_me"
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  describe "collaborators with case access", :with_stubbed_mailer do
    before do
      AddTeamToCase.call!(
        investigation: other_user_other_team_investigation,
        user: user,
        team: chosen_team,
        collaboration_class: Collaboration::Access::Edit
      )
    end

    context "when filtering case where my team has access" do
      let(:chosen_team) { team }

      scenario "filtering cases having a given team a collaborator" do
        within_fieldset("Teams added to case") { check "My team" }
        click_button "Apply filters"

        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_user_investigation.pretty_id)
        expect(page).to have_listed_case(investigation.pretty_id)
      end
    end

    context "when filtering case where another team has access" do
      let(:chosen_team) { other_team }

      scenario "filters the cases by other team with access" do
        within_fieldset("Teams added to case") do
          check "Other team"
          select other_team.name, from: "Name"
        end
        click_button "Apply filters"

        expect(page).to have_listed_case(other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
        expect(page).not_to have_listed_case(investigation.pretty_id)

        within_fieldset("Teams added to case") do
          expect(page).to have_checked_field("Other team")
          expect(page).to have_select("Name", with_options: [other_team.name])
        end
      end
    end
  end

  scenario "filtering cases where the user’s team is the owner" do
    within_fieldset("Case owner") { check "My team" }
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases where the owner is someone else" do
    check "Other person or team", id: "case_owner_is_someone_else"
    click_button "Apply filters"
    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases where another person or team is the owner" do
    within_fieldset("Case owner") do
      check "Other person or team", id: "case_owner_is_someone_else"
      select other_team.name, from: "case_owner_is_someone_else_id"
    end
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)

    check "Other person or team", id: "case_owner_is_someone_else"
    select other_user_same_team.name, from: "case_owner_is_someone_else_id"
    click_button "Apply filters"

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "combining filters" do
    within_fieldset "Case owner" do
      check "My team"
      check "Other person or team", id: "case_owner_is_someone_else"
      select other_user_other_team.name, from: "case_owner_is_someone_else_id"
    end
    click_button "Apply filters"

    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(another_team_investigation.pretty_id)
  end

  scenario "Filtering to coronavirus-related cases only" do
    check "Coronavirus cases only"
    click_on "Apply filters"

    expect(page.find_field("Coronavirus cases only")).to be_checked

    expect(page).to have_listed_case(coronavirus_investigation.pretty_id)

    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "Filtering by risk-level cases only" do
    check "Serious and high risk cases only"
    click_on "Apply filters"
    expect(page).to have_checked_field("Serious and high risk cases only")

    expect(page).to have_listed_case(serious_risk_level_investigation.pretty_id)
    expect(page).to have_listed_case(high_risk_level_investigation.pretty_id)
    expect(page).to have_css(".app-badge--risk-high", text: "High risk case")

    expect(page).not_to have_listed_case(coronavirus_investigation.pretty_id)
    expect(page).not_to have_listed_case(investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "filtering cases assigned to me via homepage link" do
    visit "/"
    click_link "Your cases"

    expect(page).to have_listed_case(investigation.pretty_id)

    expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
  end

  scenario "search returning a restricted cases" do
    fill_in "Keywords", with: restricted_case_title
    click_on "Search"

    expect(page).not_to have_link(restricted_case.title, href: "/cases/#{restricted_case.pretty_id}")
  end

  describe "sorting" do
    let(:default_filtered_cases) { Investigation.where(is_closed: false) }
    let(:cases) { default_filtered_cases.order(updated_at: :desc) }

    def select_sorting_option(option)
      within_fieldset("Sort by") { choose(option) }
      click_button "Apply filters"
    end

    context "with no sort by option selected" do
      it "shows results by most recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by most recently updated option selected" do
      before { select_sorting_option("Most recently updated") }

      it "shows results by most recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by least recently updated option selected" do
      let(:cases) { default_filtered_cases.order(updated_at: :asc) }

      before { select_sorting_option("Least recently updated") }

      it "shows results by least recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by most recently created option selected" do
      let(:cases) { default_filtered_cases.order(created_at: :desc) }

      before { select_sorting_option("Most recently created") }

      it "shows results by most recently created" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end
  end
end
