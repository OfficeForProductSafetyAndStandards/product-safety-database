require "rails_helper"

RSpec.feature "Changing ownership for an investigation", :with_stubbed_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, team:, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user) }

  let!(:another_active_user) { create(:user, :activated, name: "other user same team", organisation: user.organisation, team:) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, team:) }
  let!(:another_active_user_another_team) { create(:user, :activated, name: "another user in another team", organisation: user.organisation, team: create(:team)) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive, organisation: user.organisation, team: create(:team)) }
  let!(:deleted_team) { create(:team, :deleted) }

  context "when user is not opss" do
    before do
      create_opss_teams
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/assign/new"
    end

    scenario "does not show inactive users or teams" do
      expect(page).to have_css("#change_case_owner_form_select_team_member option[value=\"#{another_active_user.id}\"]")
      expect(page).not_to have_css("#change_case_owner_form_select_team_member option[value=\"#{another_inactive_user.id}\"]")

      expect(page).to have_css("#change_case_owner_form_select_other_team option[value=\"#{another_active_user_another_team.team.id}\"]")
      expect(page).not_to have_css("#change_case_owner_form_select_other_team option[value=\"#{deleted_team.id}\"]")

      expect(page).to have_css("#change_case_owner_form_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
      expect(page).not_to have_css("#change_case_owner_form_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
    end

    scenario "shows OPSS management team" do
      expect(page).to have_field("OPSS Incident Management")
      # expect(find_field("OPSS Incident Management")).to eq true
    end

    scenario "does not show OPSS Trading Standards Co-ordination team" do
      expect(page).not_to have_field("OPSS Trading Standards Co-ordination")
    end

    scenario "does not show OPSS Enforcement team" do
      expect(page).not_to have_field("OPSS Enforcement")
    end

    scenario "does not show OPSS Operational support unit team" do
      expect(page).not_to have_field("OPSS Operational support unit")
    end

    scenario "has current owner pre-selected" do
      expect(page).to have_checked_field(user.name)
    end

    scenario "change owner to the same user" do
      choose user.name
      click_button "Continue"

      fill_and_submit_change_owner_reason_form

      expect_page_to_show_case_owner(user)
    end

    scenario "change owner to other user in same team" do
      # Test validation errors
      choose("Someone else in your team")

      click_button "Continue"

      expect(page).to have_summary_error("Select case owner")

      choose("Someone else in your team")
      select another_active_user.name, from: "change_case_owner_form_select_team_member"
      click_button "Continue"

      fill_and_submit_change_owner_reason_form

      expect_confirmation_banner("Case owner changed to #{another_active_user.name}")
      expect_page_to_show_case_owner(another_active_user)
      expect_activity_page_to_show_case_owner_changed_to(another_active_user)
    end

    scenario "change owner to your team" do
      choose user.team.name
      click_button "Continue"

      fill_and_submit_change_owner_reason_form

      expect_confirmation_banner("Case owner changed to #{user.team.name}")
      expect_page_to_show_case_owner(user.team)
      expect_activity_page_to_show_case_owner_changed_to(user.team)
    end

    scenario "a case owned by someone else in another team can no longer have ownership changed by original owner" do
      choose("Someone else")
      select another_active_user_another_team.name, from: "change_case_owner_form_select_someone_else"
      click_button "Continue"

      fill_and_submit_change_owner_reason_form

      expect_page_to_show_case_owner(another_active_user_another_team)
      expect_activity_page_to_show_case_owner_changed_to(another_active_user_another_team)

      within('nav[aria-label="Secondary"]') { click_link "Case" }
      expect(page).not_to have_link("Change owner")
    end
  end

  context "when user is opss" do
    before do
      create_opss_teams
      user.roles.create!(name: "opss")
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/assign/new"
    end

    scenario "shows OPSS management team" do
      expect(page).to have_field("OPSS Incident Management")
      # expect(find_field("OPSS Incident Management")).to eq true
    end

    scenario "shows OPSS Trading Standards Co-ordination team" do
      expect(page).to have_field("OPSS Trading Standards Co-ordination")
    end

    scenario "shows OPSS Enforcement team" do
      expect(page).to have_field("OPSS Enforcement")
    end
  end

  context "when investigation has other teams added to the case" do
    let(:other_team_with_edit_access) { create(:team) }
    let(:other_team_with_read_only_access) { create(:team) }

    before do
      AddTeamToCase.call(
        team: other_team_with_edit_access,
        message: "na",
        investigation:,
        collaboration_class: Collaboration::Access::Edit,
        user:,
        silent: true
      )

      AddTeamToCase.call(
        team: other_team_with_read_only_access,
        message: "na",
        investigation:,
        collaboration_class: Collaboration::Access::ReadOnly,
        user:,
        silent: true
      )
    end

    scenario "shows other teams in the `Other teams added to the case` section" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/assign/new"
      expect(page).to have_css(".govuk-radios__divider", text: "Other teams added to the case")
      expect(page).to have_field(other_team_with_edit_access.name)
      expect(page).to have_field(other_team_with_read_only_access.name)
    end
  end

  context "when investigation has no other teams added to the case" do
    let(:other_team) { create(:team) }

    scenario "does not show `Other teams added to the case` section" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}/assign/new"
      expect(page).not_to have_css(".govuk-radios__divider", text: "Other teams added to the case")
      expect(page).not_to have_css(".govuk-radios__divider", text: "Other teams added to the case")
    end
  end

  def fill_and_submit_change_owner_reason_form
    fill_in "change_case_owner_form_owner_rationale", with: "Test assign"
    click_button "Confirm change"
  end

  def expect_page_to_show_case_owner(owner)
    expect(page.find("dt", text: "Case owner")).to have_sibling("dd", text: owner.name)
  end

  def expect_activity_page_to_show_case_owner_changed_to(owner)
    click_link "Activity"
    expect(page).to have_css("h3", text: "Case owner changed to #{owner.name}")
    expect(page).to have_css("p", text: "Test assign")
  end

  def create_opss_teams
    ["OPSS Enforcement", "OPSS Incident Management", "OPSS Trading Standards Co-ordination", "OPSS Operational support unit"].each do |name|
      create(:team, name:)
    end
  end
end
