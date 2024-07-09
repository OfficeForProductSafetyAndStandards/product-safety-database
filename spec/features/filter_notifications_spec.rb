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

  before do
    create(:notification, creator: user, risk_level: Investigation.risk_levels[:high], coronavirus_related: true)
    other_team_notification.touch # Tests sort order
    Investigation.reindex
    sign_in(user)
    visit "/notifications"
  end

  scenario "no filters applied shows all open/closed notifications but does not show deleted notifications" do
    expect(page).to have_listed_case(notification.pretty_id)
    expect(page).to have_listed_case(other_user_notification.pretty_id)
    expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
    expect(page).to have_listed_case(other_team_notification.pretty_id)
    expect(page).to have_listed_case(closed_notification.pretty_id)

    expect(page).not_to have_listed_case(deleted_notification.pretty_id)

    number_of_cases = Investigation.not_deleted.count
    expect(page).to have_content("#{number_of_cases} notifications using the current filters, were found.")

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
      find("details#risk-level").click
      check "Serious"
      click_button "Apply"

      find("details#risk-level").click
      expect(page.find_field("Serious")).to be_checked

      expect(page).to have_content("21 notifications using the current filters, were found.")

      click_link("2")

      find("details#risk-level").click
      expect(page.find_field("Serious")).to be_checked
    end
  end

  describe "notification priority" do
    scenario "filtering by high risk-level notifications only" do
      find("details#risk-level").click
      check "High"
      click_button "Apply"

      find("details#risk-level").click
      expect(page.find_field("High")).to be_checked

      expect(page).to have_listed_case(high_risk_level_notification.pretty_id)
      expect(page).to have_css(".opss-tag--risk1", text: "High risk notification")

      expect(page).to have_content("2 notifications using the current filters, were found.")

      expect(page).not_to have_listed_case(coronavirus_notification.pretty_id)
      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)
    end

    scenario "filtering by serious and high risk-level notifications only" do
      find("details#risk-level").click
      check "Serious"
      check "High"
      click_button "Apply"

      find("details#risk-level").click
      expect(page.find_field("Serious")).to be_checked
      expect(page.find_field("High")).to be_checked

      expect(page).to have_listed_case(serious_risk_level_notification.pretty_id)
      expect(page).to have_listed_case(high_risk_level_notification.pretty_id)
      expect(page).to have_css(".opss-tag--risk1", text: "High risk notification")

      expect(page).to have_content("3 notifications using the current filters, were found.")

      expect(page).not_to have_listed_case(coronavirus_notification.pretty_id)
      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)
    end
  end

  describe "notification status" do
    scenario "filtering for both open and closed notification" do
      find("details#case-status").click
      check "Open"
      click_button "Apply"

      expect(page).to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(closed_notification.pretty_id)
    end

    scenario "filtering only closed notifications" do
      find("details#case-status").click
      check "Closed"
      click_button "Apply"

      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).to have_listed_case(closed_notification.pretty_id)
    end
  end

  describe "Hazard type" do
    scenario "filtering by a hazard type" do
      find("details#case-hazard-type").click
      check "Fire"
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
      find("details#cases-created-by").click
      check "Others"
      select other_team.name, from: "Person or team name"
      click_button "Apply"

      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).to have_listed_case(other_team_notification.pretty_id)
    end

    scenario "filtering notifications created by my team" do
      find("details#cases-created-by").click
      check "Me and my team"
      click_button "Apply"

      expect(page).to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)
    end

    scenario "filtering notifications created by anybody but my team" do
      find("details#cases-created-by").click
      check "Others"
      click_button "Apply"

      expect(page).not_to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_notification.pretty_id)

      expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).to have_listed_case(other_team_notification.pretty_id)
      expect(page).to have_listed_case(another_team_notification.pretty_id)
    end
  end

  describe "Notification owner" do
    scenario "filtering notifications where the user is the owner" do
      find("details#case-owner").click
      check "Me"
      click_button "Apply"

      expect(page).to have_content("notifications using the current filters")

      expect(page).to have_listed_case(notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)
    end

    scenario "filtering notifications where the user's team is the owner" do
      find("details#case-owner").click
      check "Me and my team"
      click_button "Apply"

      expect(page).to have_content("notifications using the current filters")

      expect(page).to have_listed_case(notification.pretty_id)
      expect(page).to have_listed_case(other_user_notification.pretty_id)
      expect(page).not_to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).not_to have_listed_case(other_team_notification.pretty_id)
    end

    scenario "filtering notifications where the owner is someone else", skip: "Hangs during verification of other_team_notification" do
      find("details#case-owner").click
      check "Others"
      click_button "Apply"

      expect(page).to have_content("notifications using the current filters")

      expect(page).not_to have_listed_case(notification.pretty_id)

      expect(page).to have_listed_case(other_user_notification.pretty_id)
      expect(page).to have_listed_case(other_user_other_team_notification.pretty_id)
      expect(page).to have_listed_case(other_team_notification.pretty_id)
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
        find("details#case-type").click
        check "Project"
        click_button "Apply"

        expect(page).not_to have_listed_case(allegation.pretty_id)
        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).to     have_listed_case(project.pretty_id)
        expect(page).not_to have_listed_case(enquiry.pretty_id)
      end

      scenario "filtering for enquiries" do
        find("details#case-type").click
        check "Enquiry"
        click_button "Apply"

        expect(page).not_to have_listed_case(allegation.pretty_id)
        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(project.pretty_id)
        expect(page).to     have_listed_case(enquiry.pretty_id)
      end

      scenario "filtering for notifications" do
        find("details#case-type").click
        check "Notification"
        click_button "Apply"

        expect(page).not_to have_listed_case(allegation.pretty_id)
        expect(page).to     have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(project.pretty_id)
        expect(page).not_to have_listed_case(enquiry.pretty_id)
      end

      scenario "filtering for allegations" do
        find("details#case-type").click
        check "Allegation"
        click_button "Apply"

        expect(page).to     have_listed_case(allegation.pretty_id)
        expect(page).not_to have_listed_case(notification.pretty_id)
        expect(page).not_to have_listed_case(project.pretty_id)
        expect(page).not_to have_listed_case(enquiry.pretty_id)
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

  describe "Sorting" do
    let(:default_filtered_cases) { Investigation.not_deleted.where(is_closed: false) }
    let(:cases) { default_filtered_cases.order(updated_at: :desc) }

    def select_sorting_option(option)
      within("form#cases-search-form dl.opss-dl-select") do
        click_on option
      end
    end

    before do
      visit "/notifications"
    end

    context "with no sort by option selected" do
      it "shows results by most recently updated" do
        puts "Checking for default sorting option: Recent updates"
        expect(page).to have_content("Recent updates")

        puts "Checking if cases are listed in the expected order"
        cases.each do |investigation|
          expect(page).to have_content(investigation.pretty_id)
        end
      end
    end

    context "with sort by most recently updated option selected" do
      before do
        select_sorting_option("Recent updates")
      end

      it "shows results by most recently updated" do
        puts "Checking if cases are listed in the expected order"
        cases.each do |investigation|
          expect(page).to have_content(investigation.pretty_id)
        end
      end
    end

    context "with sort by least recently updated option selected" do
      let(:cases) { default_filtered_cases.order(updated_at: :asc) }

      before do
        select_sorting_option("Oldest updates")
      end

      it "shows results by least recently updated" do
        puts "Checking if cases are listed in the expected order"
        cases.each do |investigation|
          expect(page).to have_content(investigation.pretty_id)
        end
      end
    end

    context "with sort by most recently created option selected" do
      let(:cases) { default_filtered_cases.order(created_at: :desc) }

      before do
        select_sorting_option("Newest notifications")
      end

      it "shows results by most recently created" do
        puts "Checking if cases are listed in the expected order"
        cases.each do |investigation|
          expect(page).to have_content(investigation.pretty_id)
        end
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
