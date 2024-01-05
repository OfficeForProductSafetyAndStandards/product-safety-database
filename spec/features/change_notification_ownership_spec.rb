require "rails_helper"

RSpec.feature "Changing notification ownership", :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, team:, has_viewed_introduction: true) }
  let(:notification) { create(:notification, creator: user) }

  let!(:another_active_user) { create(:user, :activated, name: "other user same team", organisation: user.organisation, team:) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, team:) }
  let!(:another_active_user_another_team) { create(:user, :activated, name: "another user in another team", organisation: user.organisation, team: create(:team)) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive, organisation: user.organisation, team: create(:team)) }
  let!(:deleted_team) { create(:team, :deleted) }

  context "when user is not opss" do
    before do
      create_opss_teams
      sign_in(user)
      visit "/cases/#{notification.pretty_id}/assign/new"
      expect_to_have_notification_breadcrumbs
    end

    scenario "does not show inactive users or teams" do
      expect(page).to have_css("#change_notification_owner_form_select_team_member option[value=\"#{another_active_user.id}\"]")
      expect(page).not_to have_css("#change_notification_owner_form_select_team_member option[value=\"#{another_inactive_user.id}\"]")

      expect(page).to have_css("#change_notification_owner_form_select_other_team option[value=\"#{another_active_user_another_team.team.id}\"]")
      expect(page).not_to have_css("#change_notification_owner_form_select_other_team option[value=\"#{deleted_team.id}\"]")

      expect(page).to have_css("#change_notification_owner_form_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
      expect(page).not_to have_css("#change_notification_owner_form_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
    end

    scenario "shows correct fields" do
      expect(page).to have_field("OPSS Incident Management")
      expect(page).not_to have_field("OPSS Trading Standards Co-ordination")
      expect(page).not_to have_field("OPSS Enforcement")
      expect(page).not_to have_field("OPSS Operational support unit")
      expect(page).to have_checked_field(user.name)
      expect_to_have_notification_breadcrumbs
    end

    scenario "change owner to the same user" do
      choose user.name
      click_button "Continue"

      expect_to_have_notification_breadcrumbs
      fill_and_submit_change_owner_reason_form

      expect_page_to_show_case_owner(user)
    end

    scenario "change owner to other user in same team" do
      # Test validation errors
      choose("Someone else in your team")

      click_button "Continue"

      expect(page).to have_summary_error("Select notification owner")
      expect_to_have_notification_breadcrumbs

      choose("Someone else in your team")
      select another_active_user.name, from: "change_notification_owner_form_select_team_member"
      click_button "Continue"

      expect_to_have_notification_breadcrumbs
      fill_and_submit_change_owner_reason_form

      expect_confirmation_banner("Notification owner changed to #{another_active_user.name}")
      expect_page_to_show_case_owner(another_active_user)
      expect_activity_page_to_show_case_owner_changed_to(another_active_user)
    end

    scenario "change owner to your team" do
      choose user.team.name
      click_button "Continue"

      expect_to_have_notification_breadcrumbs
      fill_and_submit_change_owner_reason_form

      expect_confirmation_banner("Notification owner changed to #{user.team.name}")
      expect_page_to_show_case_owner(user.team)
      expect_activity_page_to_show_case_owner_changed_to(user.team)
    end

    scenario "a case owned by someone else in another team can no longer have ownership changed by original owner" do
      choose("Someone else")
      select another_active_user_another_team.name, from: "change_notification_owner_form_select_someone_else"
      click_button "Continue"

      expect_to_have_notification_breadcrumbs
      fill_and_submit_change_owner_reason_form

      expect_page_to_show_case_owner(another_active_user_another_team)
      expect_activity_page_to_show_case_owner_changed_to(another_active_user_another_team)

      within('nav[aria-label="Secondary"]') { click_link "Notification" }
      expect(page).not_to have_link("Change owner")
    end
  end

  context "when user is opss" do
    before do
      create_opss_teams
      user.roles.create!(name: "opss")
      sign_in(user)
      visit "/cases/#{notification.pretty_id}/assign/new"
    end

    scenario "shows correct fields" do
      expect(page).to have_field("OPSS Incident Management")
      expect(page).to have_field("OPSS Trading Standards Co-ordination")
      expect(page).to have_field("OPSS Enforcement")
      expect_to_have_notification_breadcrumbs
    end
  end

  context "when notification has other teams added to the case" do
    let(:other_team_with_edit_access) { create(:team) }
    let(:other_team_with_read_only_access) { create(:team) }

    before do
      AddTeamToNotification.call(
        team: other_team_with_edit_access,
        message: "na",
        investigation: notification,
        collaboration_class: Collaboration::Access::Edit,
        user:,
        silent: true
      )

      AddTeamToNotification.call(
        team: other_team_with_read_only_access,
        message: "na",
        investigation: notification,
        collaboration_class: Collaboration::Access::ReadOnly,
        user:,
        silent: true
      )
    end

    scenario "shows other teams in the `Other teams added to the case` section" do
      sign_in(user)
      visit "/cases/#{notification.pretty_id}/assign/new"
      expect_to_have_notification_breadcrumbs
      expect(page).to have_css(".govuk-radios__divider", text: "Other teams added to the notification")
      expect(page).to have_field(other_team_with_edit_access.name)
      expect(page).to have_field(other_team_with_read_only_access.name)
    end
  end

  context "when investigation has no other teams added to the case" do
    let(:other_team) { create(:team) }

    scenario "does not show `Other teams added to the case` section" do
      sign_in(user)
      visit "/cases/#{notification.pretty_id}/assign/new"
      expect_to_have_notification_breadcrumbs
      expect(page).not_to have_css(".govuk-radios__divider", text: "Other teams added to the notification")
      expect(page).not_to have_css(".govuk-radios__divider", text: "Other teams added to the notification")
    end
  end

  def fill_and_submit_change_owner_reason_form
    fill_in "change_notification_owner_form_owner_rationale", with: "Test assign"
    click_button "Confirm change"
  end

  def expect_page_to_show_case_owner(owner)
    expect(page.find("dt", text: "Notification owner")).to have_sibling("dd", text: owner.name)
  end

  def expect_activity_page_to_show_case_owner_changed_to(owner)
    click_link "Activity"
    expect(page).to have_css("h3", text: "Notification owner changed to #{owner.name}")
    expect(page).to have_css("p", text: "Test assign")
  end

  def create_opss_teams
    ["OPSS Enforcement", "OPSS Incident Management", "OPSS Trading Standards Co-ordination", "OPSS Operational support unit"].each do |name|
      create(:team, name:)
    end
  end
end
