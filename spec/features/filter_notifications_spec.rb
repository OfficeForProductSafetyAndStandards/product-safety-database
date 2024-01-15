require "rails_helper"

RSpec.feature "Notification filtering", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:other_organisation) { create(:organisation) }

  let(:organisation)          { create(:organisation) }
  let(:team)                  { create(:team, organisation:) }
  let(:other_team)            { create(:team, organisation:, name: "other team") }
  let(:user)                  { create(:user, :activated, :opss_user, organisation:, team:, has_viewed_introduction: true) }
  let(:other_user_same_team)  { create(:user, :activated, name: "other user same team", organisation:, team:) }
  let(:yet_another_user_same_team) { create(:user, :activated, name: "yet another user same team", organisation:, team: other_team) }
  let(:other_user_other_team) { create(:user, :activated, name: "other user other team", organisation:, team: other_team) }

  let!(:notification) { create(:notification, creator: user, hazard_type: "Fire") }
  let!(:deleted_notification)               { create(:notification, creator: user, hazard_type: "Fire", deleted_at: Time.zone.now) }
  let!(:other_user_notification)            { create(:notification, creator: other_user_same_team, hazard_type: "Fire") }
  let!(:other_user_other_team_notification) { create(:notification, creator: other_user_other_team) }
  let!(:other_team_notification)            { create(:notification, creator: yet_another_user_same_team, hazard_type: "Fire") }
  let!(:another_team_notification)          { create(:notification, creator: create(:user)) }

  let!(:closed_notification) { create(:notification, :closed) }
  let!(:allegation) { create(:allegation) }
  let!(:project) { create(:project) }
  let!(:enquiry) { create(:enquiry) }

  let!(:coronavirus_notification)        { create(:notification, creator: user, coronavirus_related: true) }
  let!(:serious_risk_level_notification) { create(:notification, creator: user, risk_level: Investigation.risk_levels[:serious]) }
  let!(:high_risk_level_notification)    { create(:notification, creator: user, risk_level: Investigation.risk_levels[:high]) }

  let!(:another_active_user)   { create(:user, :activated, organisation: user.organisation, team:) }
  let!(:another_inactive_user) { create(:user, :inactive,  organisation: user.organisation, team:) }
  let!(:other_deleted_team)    { create(:team, :deleted) }

  let(:restricted_notification_title) { "Restricted notification title" }
  let(:restricted_notification_team) { create(:team, organisation: other_organisation) }
  let(:restricted_notification_team_user) { create(:user, team: restricted_notification_team, organisation: other_organisation) }
  let!(:restricted_notification) { create(:notification, creator: restricted_notification_team_user, is_private: true, description: restricted_notification_title).decorate }

  before do
    create(:notification, creator: user, risk_level: Investigation.risk_levels[:high], coronavirus_related: true)
    other_team_notification.touch # Tests sort order
    Investigation.reindex
    sign_in(user)
    visit all_cases_investigations_path
  end

  scenario "no filters applied shows all open notifications but does not show closed or deleted notifications" do
    expect(page).to have_listed_case(notification.pretty_id)
    expect(page).to have_listed_case(other_user_notification.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
    expect(page).to have_listed_case(other_team_notification.pretty_id)

    expect(page).not_to have_listed_case(deleted_notification.pretty_id)
    expect(page).not_to have_listed_case(closed_notification.pretty_id)
    number_of_open_cases = Investigation.not_deleted.where(is_closed: false).count
    expect(page).to have_content("#{number_of_open_cases} notifications using the current filters, were found.")

    expect(find("details#filter-details")["open"]).to eq(nil)

    find("details#filter-details").click
    within_fieldset "Notification status" do
      expect(page).to have_checked_field("Open")
      expect(page).to have_unchecked_field("Closed")
    end

    expect(page).to have_content("#{number_of_open_cases} notifications using the current filters, were found.")

    within "#sort-by-fieldset" do
      expect(page).to have_select("Sort the results by", selected: "Recent updates")
    end
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Recent updates")
  end

  context "when there are multiple pages of notifications" do
    before do
      20.times { create(:notification, creator: user, risk_level: Investigation.risk_levels[:serious]) }
      Investigation.reindex
    end

    it "maintains the filters when clicking on additional pages" do
      choose "Serious and high risk"
      click_on "Apply"

      expect(page.find_field("Serious and high risk")).to be_checked

      click_link("2")

      expect(page.find_field("Serious and high risk")).to be_checked
    end
  end

  describe "notification priority" do
    scenario "filtering by serious and high risk-level notifications only" do
      choose "Serious and high risk"
      click_on "Apply"
      expect(page).to have_checked_field("Serious and high risk")

      expect(page).to have_listed_case(serious_risk_level_notification.pretty_id)
      expect(page).to have_listed_case(high_risk_level_notification.pretty_id)
      expect(page).to have_css(".opss-tag--risk1", text: "High risk notification")

      expect(page).not_to have_listed_case(coronavirus_notification.pretty_id)
      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)

      expect(find("details#filter-details")["open"]).to eq(nil)
    end

    describe "notification status" do
      scenario "filtering for both open and closed notification" do
        within_fieldset("Notification status") { choose "All" }
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(closed_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end

      scenario "filtering only closed notifications" do
        within_fieldset "Notification status" do
          choose "Closed"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(closed_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end
    end
  end

  context "with 'more options' expanded" do
    before do
      find("details#filter-details").click
    end

    scenario "selecting filters only shows other active users and teams in the notification owner and created by filters" do
      within_fieldset("Notification owner") do
        expect(page).to have_select("Person or team name", with_options: [team.name, other_team.name, another_active_user.name])
        expect(page).not_to have_select("Person or team name", with_options: [another_inactive_user.name, other_deleted_team.name])
      end

      within_fieldset("Created by") do
        expect(page).to have_select("Person or team name", with_options: [team.name, other_team.name, another_active_user.name])
        expect(page).not_to have_select("Person or team name", with_options: [another_inactive_user.name, other_deleted_team.name])
      end
    end

    describe "Notification owner" do
      scenario "filtering notifications where the user is the owner" do
        within_fieldset("Notification owner") { choose "Me" }
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications where the user's team is the owner" do
        within_fieldset("Notification owner") { choose "Me and my team" }
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(other_user_notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications where the owner is someone else" do
        choose "Others", id: "case_owner_others"
        click_button "Apply"
        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(other_user_notification.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications where another person or team is the owner" do
        within_fieldset("Notification owner") do
          choose "Others", id: "case_owner_others"
          select other_team.name, from: "case_owner_is_someone_else_id"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_notification.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")

        choose "Others", id: "case_owner_others"
        select other_user_same_team.name, from: "case_owner_is_someone_else_id"
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(other_user_notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end
    end

    describe "Teams added to notifications", :with_stubbed_mailer do
      before do
        AddTeamToNotification.call!(
          notification: other_user_other_team_notification,
          user:,
          team: chosen_team,
          collaboration_class: Collaboration::Access::Edit
        )
      end

      context "when filtering notifications where my team has access" do
        let(:chosen_team) { team }

        scenario "filtering notifications having a given team a collaborator" do
          within_fieldset("Teams added to notifications") { choose "My team" }
          click_button "Apply"

          expect(page).not_to have_listed_case(other_team_notification.pretty_id)
          expect(page).not_to have_listed_case(other_team_notification.pretty_id)
          expect(page).to have_listed_case(other_user_notification.pretty_id)
          expect(page).to have_listed_case(notification.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end
      end

      context "when filtering notifications where another team has access" do
        let(:chosen_team) { other_team }

        scenario "filters the notifications by other team with access" do
          within_fieldset("Teams added to notifications") do
            choose "Others"
            select other_team.name, from: "Team name"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_team_notification.pretty_id)
          expect(page).not_to have_listed_case(other_user_notification.pretty_id)
          expect(page).not_to have_listed_case(notification.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")

          within_fieldset("Teams added to notifications") do
            expect(page).to have_checked_field("Other")
            expect(page).to have_select("Team name", with_options: [other_team.name])
          end

          within_fieldset("Teams added to notifications") { choose "All" }
          within_fieldset("Notification owner")           { choose "Me and my team" }
          click_button "Apply"

          expect(page).not_to have_listed_case(other_team_notification.pretty_id)
          expect(page).to have_listed_case(notification.pretty_id)
          expect(page).to have_listed_case(other_user_notification.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end

        scenario "with keywords entered" do
          fill_in "Search", with: other_user_other_team_notification.description
          click_on "Submit search"

          find("#filter-details").click

          within_fieldset("Teams added to notifications") do
            choose "Others"
            select other_team.name, from: "Team name"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
        end
      end

      context "when filtering notifications where any other team has access" do
        let(:chosen_team) { other_team }

        scenario "filters the notifications by other team with access but do not specify team" do
          within_fieldset("Teams added to notifications") do
            choose "Other"
          end
          click_button "Apply"

          expect(page).to have_listed_case(other_team_notification.pretty_id)
          expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
          expect(page).not_to have_listed_case(other_user_notification.pretty_id)
          expect(page).not_to have_listed_case(notification.pretty_id)

          expect(find("details#filter-details")["open"]).to eq("open")
        end
      end
    end

    describe "Hazard type" do
      scenario "filtering by a hazard type" do
        select "Fire", from: "Hazard type"
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(other_user_notification.pretty_id)
        expect(page).to have_listed_case(other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(another_team_notification.pretty_id)

        number_of_total_cases = Investigation.not_deleted.where(hazard_type: "Fire").count
        expect(page).to have_content("#{number_of_total_cases} notifications using the current filters, were found.")
      end
    end

    describe "Created by" do
      scenario "filtering notifications created by another team" do
        within_fieldset("Created by") do
          choose "Others"
          select other_team.name, from: "Person or team name"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications created by my team" do
        within_fieldset("Created by") { choose "Me and my team" }
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(other_team_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications created by anybody but my team" do
        within_fieldset("Created by") { choose "Others" }
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_notification.pretty_id)

        expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
        expect(page).to have_listed_case(other_team_notification.pretty_id)
        expect(page).to have_listed_case(another_team_notification.pretty_id)

        within_fieldset("Created by") { expect(page).to have_checked_field "Others" }

        expect(find("details#filter-details")["open"]).to eq("open")
      end

      scenario "filtering notifications created by a different user" do
        within_fieldset("Created by") do
          choose "Others"
          select other_user_other_team.name, from: "Person or team name"
        end
        click_button "Apply"

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(other_user_notification.pretty_id)
        expect(page).not_to have_listed_case(other_team_notification.pretty_id)
        expect(page).not_to have_listed_case(another_team_notification.pretty_id)

        expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)

        within_fieldset("Created by") do
          expect(page).to have_checked_field "Others"
          expect(page).to have_select "Person or team name", with_options: [other_user_other_team.name]
        end

        expect(find("details#filter-details")["open"]).to eq("open")
      end
    end

    describe "notification type" do
      context "with a non OPSS user" do
        let(:user) { create(:user, :activated, organisation:, team:, has_viewed_introduction: true) }

        scenario "filter should be unavailable" do
          expect(page).not_to have_listed_case(allegation.pretty_id)
          expect(page).to have_listed_case(notification.pretty_id)
          expect(page).not_to have_listed_case(project.pretty_id)
          expect(page).not_to have_listed_case(enquiry.pretty_id)
          expect(page).not_to have_css("details#case-type", text: "Type")
        end
      end

      context "with an OPSS user" do

        scenario "filtering for projects" do
          within_fieldset "Type" do
            choose "Project"
          end
          click_button "Apply"

          expect(page).not_to have_listed_case(allegation.pretty_id)
          expect(page).not_to have_listed_case(notification.pretty_id)
          expect(page).to     have_listed_case(project.pretty_id)
          expect(page).not_to have_listed_case(enquiry.pretty_id)
        end

        scenario "filtering for enquiries" do
          within_fieldset "Type" do
            choose "Enquiry"
          end
          click_button "Apply"

          expect(page).not_to have_listed_case(allegation.pretty_id)
          expect(page).not_to have_listed_case(notification.pretty_id)
          expect(page).not_to have_listed_case(project.pretty_id)
          expect(page).to     have_listed_case(enquiry.pretty_id)
        end

        scenario "filtering for notifications" do
          within_fieldset "Type" do
            choose "Notification"
          end
          click_button "Apply"

          expect(page).not_to have_listed_case(allegation.pretty_id)
          expect(page).to     have_listed_case(notification.pretty_id)
          expect(page).not_to have_listed_case(project.pretty_id)
          expect(page).not_to have_listed_case(enquiry.pretty_id)
        end

        scenario "filtering for allegations" do
          within_fieldset "Type" do
            choose "Allegation"
          end
          click_button "Apply"

          expect(page).to     have_listed_case(allegation.pretty_id)
          expect(page).not_to have_listed_case(notification.pretty_id)
          expect(page).not_to have_listed_case(project.pretty_id)
          expect(page).not_to have_listed_case(enquiry.pretty_id)
        end
      end
    end

    describe "Notification status" do
      scenario "filtering for both open and closed cases" do
        within_fieldset("Notification status") { choose "All" }
        click_button "Apply"

        expect(page).to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(closed_notification.pretty_id)
        expect(page).not_to have_listed_case(deleted_notification.pretty_id)
        number_of_total_cases = Investigation.not_deleted.count
        expect(page).to have_content("#{number_of_total_cases} notifications using the current filters, were found.")

        expect(find("details#filter-details")["open"]).to eq(nil)
      end

      scenario "filtering only closed notifications" do
        within_fieldset "Notification status" do
          choose "Closed"
        end
        click_button "Apply"

        expect(page).to have_content("1 notification using the current filters, was found.")

        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to have_listed_case(closed_notification.pretty_id)

        expect(find("details#filter-details")["open"]).to eq(nil)
      end
    end
  end

  scenario "filtering notifications assigned to me via homepage link" do
    visit "/"
    click_link "Notifications"

    expect(page).to have_listed_case(notification.pretty_id)

    expect(page).not_to have_listed_case(other_user_notification.pretty_id)
    expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
    expect(page).not_to have_listed_case(other_team_notification.pretty_id)
  end

  scenario "search returning a restricted notifications" do
    fill_in "Search", with: restricted_notification_title
    click_on "Search"

    expect(page).not_to have_link(restricted_notification.title, href: "/cases/#{restricted_notification.pretty_id}")

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

      before { select_sorting_option("Newest notifications") }

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
          click_on "Oldest notifications"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Oldest notifications")

        within "form dl.govuk-list.opss-dl-select" do
          click_on "Newest notifications"
        end

        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest notifications")

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
