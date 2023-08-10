require "rails_helper"

RSpec.feature "Case filtering", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:other_organisation) { create(:organisation) }

  let(:organisation)          { create(:organisation) }
  let(:team)                  { create(:team, organisation:) }
  let(:other_team)            { create(:team, organisation:, name: "other team") }
  let(:user)                  { create(:user, :activated, organisation:, team:, has_viewed_introduction: true) }
  let(:other_user_same_team)  { create(:user, :activated, name: "other user same team", organisation:, team:) }
  let(:yet_another_user_same_team) { create(:user, :activated, name: "yet another user same team", organisation:, team: other_team) }
  let(:other_user_other_team) { create(:user, :activated, name: "other user other team", organisation:, team: other_team) }

  let!(:investigation)                       { create(:allegation, creator: user, hazard_type: "Fire") }
  let!(:deleted_investigation)               { create(:allegation, creator: user, hazard_type: "Fire", deleted_at: Time.zone.now) }
  let!(:other_user_investigation)            { create(:allegation, creator: other_user_same_team, hazard_type: "Fire") }
  let!(:other_user_other_team_investigation) { create(:allegation, creator: other_user_other_team) }
  let!(:other_team_investigation)            { create(:allegation, creator: yet_another_user_same_team, hazard_type: "Fire") }
  let!(:another_team_investigation)          { create(:allegation, creator: create(:user)) }

  let!(:closed_investigation) { create(:allegation, :closed) }
  let!(:project) { create(:project) }
  let!(:enquiry) { create(:enquiry) }

  let!(:coronavirus_investigation)        { create(:allegation, creator: user, coronavirus_related: true) }
  let!(:serious_risk_level_investigation) { create(:allegation, creator: user, risk_level: Investigation.risk_levels[:serious]) }
  let!(:high_risk_level_investigation)    { create(:allegation, creator: user, risk_level: Investigation.risk_levels[:high]) }

  let!(:another_active_user)   { create(:user, :activated, organisation: user.organisation, team:) }
  let!(:another_inactive_user) { create(:user, :inactive,  organisation: user.organisation, team:) }
  let!(:other_deleted_team)    { create(:team, :deleted) }

  let(:restricted_case_title) { "Restricted case title" }
  let(:restricted_case_team) { create(:team, organisation: other_organisation) }
  let(:restricted_case_team_user) { create(:user, team: restricted_case_team, organisation: other_organisation) }
  let!(:restricted_case) { create(:allegation, creator: restricted_case_team_user, is_private: true, description: restricted_case_title).decorate }

  before do
    create(:allegation, creator: user, risk_level: Investigation.risk_levels[:high], coronavirus_related: true)
    other_team_investigation.touch # Tests sort order
    Investigation.reindex
    sign_in(user)
    visit all_cases_investigations_path
  end

  scenario "no filters applied shows all open cases but does not show closed or deleted cases" do
    expect(page).to have_listed_case(investigation.pretty_id)
    expect(page).to have_listed_case(other_user_investigation.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
    expect(page).to have_listed_case(other_team_investigation.pretty_id)

    expect(page).not_to have_listed_case(deleted_investigation.pretty_id)
    expect(page).not_to have_listed_case(closed_investigation.pretty_id)
    number_of_open_cases = Investigation.not_deleted.where(is_closed: false).count
    expect(page).to have_content("#{number_of_open_cases} cases using the current filters, were found.")

    expect(find("details#filter-details")["open"]).to eq(nil)

    find("details#filter-details").click
    within_fieldset "Case status" do
      expect(page).to have_checked_field("Open")
      expect(page).to have_unchecked_field("Closed")
    end

    expect(page).to have_content("#{number_of_open_cases} cases using the current filters, were found.")

    within "#sort-by-fieldset" do
      expect(page).to have_select("Sort the results by", selected: "Recent updates")
    end
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Recent updates")
  end

  context "when there are multiple pages of cases" do
    before do
      20.times { create(:allegation, creator: user, risk_level: Investigation.risk_levels[:serious]) }
      Investigation.reindex
    end

    it "maintains the filters when clicking on additional pages" do
      choose "Serious and high risk"
      click_on "Apply"

      expect(page.find_field("Serious and high risk")).to be_checked

      click_link("page-2-link")

      expect(page.find_field("Serious and high risk")).to be_checked
    end
  end

  describe "Case priority" do
    scenario "filtering by serious and high risk-level cases only" do
      choose "Serious and high risk"
      click_on "Apply"
      expect(page).to have_checked_field("Serious and high risk")

      expect(page).to have_listed_case(serious_risk_level_investigation.pretty_id)
      expect(page).to have_listed_case(high_risk_level_investigation.pretty_id)
      expect(page).to have_css(".opss-tag--risk1", text: "High risk case")

      expect(page).not_to have_listed_case(coronavirus_investigation.pretty_id)
      expect(page).not_to have_listed_case(investigation.pretty_id)
      expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
      expect(page).not_to have_listed_case(other_team_investigation.pretty_id)

      expect(find("details#filter-details")["open"]).to eq(nil)
    end

    describe "Case status" do
      scenario "filtering for both open and closed cases" do
        within_fieldset("Case status") { choose "All" }
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(closed_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end

      scenario "filtering only closed cases" do
        within_fieldset "Case status" do
          choose "Closed"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(closed_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end
    end
  end

  context "with 'more options' expanded" do
    before do
      find("details#filter-details").click
    end

    scenario "selecting filters only shows other active users and teams in the case owner and created by filters" do
      within_fieldset("Case owner") do
        expect(page).to have_select("Person or team name", with_options: [team.name, other_team.name, another_active_user.name])
        expect(page).not_to have_select("Person or team name", with_options: [another_inactive_user.name, other_deleted_team.name])
      end

      within_fieldset("Created by") do
        expect(page).to have_select("Person or team name", with_options: [team.name, other_team.name, another_active_user.name])
        expect(page).not_to have_select("Person or team name", with_options: [another_inactive_user.name, other_deleted_team.name])
      end
    end

    describe "Case owner" do
      scenario "filtering cases where the user is the owner" do
        within_fieldset("Case owner") { choose "Me" }
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering cases where the user’s team is the owner" do
        within_fieldset("Case owner") { choose "Me and my team" }
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(other_user_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering cases where the owner is someone else" do
        choose "Others", id: "case_owner_others"
        click_button "Apply"
        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(other_user_investigation.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering cases where another person or team is the owner" do
        within_fieldset("Case owner") do
          choose "Others", id: "case_owner_others"
          select other_team.name, from: "case_owner_is_someone_else_id"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")

        choose "Others", id: "case_owner_others"
        select other_user_same_team.name, from: "case_owner_is_someone_else_id"
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(other_user_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end
    end

    describe "Teams added to cases", :with_stubbed_mailer do
      before do
        AddTeamToCase.call!(
          investigation: other_user_other_team_investigation,
          user:,
          team: chosen_team,
          collaboration_class: Collaboration::Access::Edit
        )
      end

      context "when filtering case where my team has access" do
        let(:chosen_team) { team }

        scenario "filtering cases having a given team a collaborator" do
          within_fieldset("Teams added to cases") { choose "My team" }
          click_button "Apply"

          expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
          expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
          expect(page).to have_listed_case(other_user_investigation.pretty_id)
          expect(page).to have_listed_case(investigation.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end
      end

      context "when filtering case where another team has access" do
        let(:chosen_team) { other_team }

        scenario "filters the cases by other team with access" do
          within_fieldset("Teams added to cases") do
            choose "Others"
            select other_team.name, from: "Team name"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_team_investigation.pretty_id)
          expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
          expect(page).not_to have_listed_case(investigation.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")

          within_fieldset("Teams added to cases") do
            expect(page).to have_checked_field("Other")
            expect(page).to have_select("Team name", with_options: [other_team.name])
          end

          within_fieldset("Teams added to cases") { choose "All" }
          within_fieldset("Case owner")           { choose "Me and my team" }
          click_button "Apply"

          expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
          expect(page).to have_listed_case(investigation.pretty_id)
          expect(page).to have_listed_case(other_user_investigation.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end

        scenario "with keywords entered" do
          fill_in "Search", with: other_user_other_team_investigation.description
          click_on "Submit search"

          find("#filter-details").click

          within_fieldset("Teams added to cases") do
            choose "Others"
            select other_team.name, from: "Team name"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
        end
      end

      context "when filtering case where any other team has access" do
        let(:chosen_team) { other_team }

        scenario "filters the cases by other team with access but do not specify team" do
          within_fieldset("Teams added to cases") do
            choose "Other"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_team_investigation.pretty_id)
          expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
          expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
          expect(page).not_to have_listed_case(investigation.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end
      end
    end

    describe "Hazard type" do
      scenario "filtering by a hazard type" do
        select "Fire", from: "Hazard type"
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(other_user_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(another_team_investigation.pretty_id)

        number_of_total_cases = Investigation.not_deleted.where(hazard_type: "Fire").count
        expect(page).to have_content("#{number_of_total_cases} cases using the current filters, were found.")
      end
    end

    describe "Created by" do
      scenario "filtering investigations created by another team" do
        within_fieldset("Created by") do
          choose "Others"
          select other_team.name, from: "Person or team name"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering investigations created by my team" do
        within_fieldset("Created by") { choose "Me and my team" }
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering investigations created by anybody but my team" do
        within_fieldset("Created by") { choose "Others" }
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_investigation.pretty_id)

        expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)
        expect(page).to have_listed_case(other_team_investigation.pretty_id)
        expect(page).to have_listed_case(another_team_investigation.pretty_id)

        within_fieldset("Created by") { expect(page).to have_checked_field "Others" }

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering investigations created by a different user" do
        within_fieldset("Created by") do
          choose "Others"
          select other_user_other_team.name, from: "Person or team name"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(other_user_investigation.pretty_id)
        expect(page).not_to have_listed_case(other_team_investigation.pretty_id)
        expect(page).not_to have_listed_case(another_team_investigation.pretty_id)

        expect(page).to have_listed_case(other_user_other_team_investigation.pretty_id)

        within_fieldset("Created by") do
          expect(page).to have_checked_field "Others"
          expect(page).to have_select "Person or team name", with_options: [other_user_other_team.name]
        end

        expect(find("details#filter-details")["open"]).to eq("open")
      end
    end

    describe "Case type" do
      scenario "filtering for projects" do
        within_fieldset "Case type" do
          choose "Project"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(project.pretty_id)
        expect(page).not_to have_listed_case(enquiry.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering for enquiries" do
        within_fieldset "Case type" do
          choose "Enquiry"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(project.pretty_id)
        expect(page).to have_listed_case(enquiry.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering for allegations" do
        within_fieldset "Case type" do
          choose "Allegation"
        end
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).not_to have_listed_case(project.pretty_id)
        expect(page).not_to have_listed_case(enquiry.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end
    end

    describe "Case status" do
      scenario "filtering for both open and closed cases" do
        within_fieldset("Case status") { choose "All" }
        click_button "Apply"

        expect(page).to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(closed_investigation.pretty_id)
        expect(page).not_to have_listed_case(deleted_investigation.pretty_id)
        number_of_total_cases = Investigation.not_deleted.count
        expect(page).to have_content("#{number_of_total_cases} cases using the current filters, were found.")

        expect(find("details#filter-details")["open"]).to eq(nil)
      end

      scenario "filtering only closed cases" do
        within_fieldset "Case status" do
          choose "Closed"
        end
        click_button "Apply"

        expect(page).to have_content("1 case using the current filters, was found.")

        expect(page).not_to have_listed_case(investigation.pretty_id)
        expect(page).to have_listed_case(closed_investigation.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end
    end
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
    fill_in "Search", with: restricted_case_title
    click_on "Search"

    expect(page).not_to have_link(restricted_case.title, href: "/cases/#{restricted_case.pretty_id}")

    expect(find("details#filter-details")["open"]).to eq(nil)
  end

  describe "Sorting" do
    let(:default_filtered_cases) { Investigation.not_deleted.where(is_closed: false) }
    let(:cases) { default_filtered_cases.order(updated_at: :desc) }

    def select_sorting_option(option)
      within("form#cases-search-form dl.opss-dl-select") do
        click_on option
      end
    end

    context "with no sort by option selected" do
      it "shows results by most recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by most recently updated option selected" do
      before { select_sorting_option("Recent updates") }

      it "shows results by most recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by least recently updated option selected" do
      let(:cases) { default_filtered_cases.order(updated_at: :asc) }

      before { select_sorting_option("Oldest updates") }

      it "shows results by least recently updated" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "with sort by most recently created option selected" do
      let(:cases) { default_filtered_cases.order(created_at: :desc) }

      before { select_sorting_option("Newest cases") }

      it "shows results by most recently created" do
        expect(page).to list_cases_in_order(cases.map(&:pretty_id))
      end
    end

    context "when user has searched" do
      before do
        fill_in "Search", with: "xyz"
        click_button "Submit search"
      end

      it "is initially sorted by relevant" do
        expect(page).to have_content "Sort the results by Relevance"
      end

      it "allows user to sort by other options" do
        within "form dl.govuk-list.opss-dl-select" do
          click_on "Oldest cases"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Oldest cases")

        within "form dl.govuk-list.opss-dl-select" do
          click_on "Newest cases"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest cases")

        within "form dl.govuk-list.opss-dl-select" do
          click_on "Oldest updates"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Oldest updates")

        within "form dl.govuk-list.opss-dl-select" do
          click_on "Recent updates"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Recent updates")
      end
    end
  end
end
