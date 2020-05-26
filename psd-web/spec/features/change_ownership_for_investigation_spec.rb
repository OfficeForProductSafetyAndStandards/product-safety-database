require "rails_helper"

RSpec.feature "Changing ownership for an investigation", :with_stubbed_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, team: team, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, owner: user) }

  let!(:another_active_user) { create(:user, :activated, name: "other user same team", organisation: user.organisation, team: team) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, team: team) }
  let!(:another_active_user_another_team) { create(:user, :activated, name: "another user in another team", organisation: user.organisation, team: create(:team)) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive, organisation: user.organisation, team: create(:team)) }

  before do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}/assign/select-owner"
  end

  scenario "does not show inactive users" do
    expect(page).to have_css("#investigation_select_team_member option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#investigation_select_team_member option[value=\"#{another_inactive_user.id}\"]")

    expect(page).to have_css("#investigation_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
    expect(page).not_to have_css("#investigation_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
  end

  scenario "change owner to the same user" do
    choose user.name
    click_button "Continue"

    fill_and_submit_change_owner_reason_form

    expect_page_to_show_case_owner(user)
  end

  scenario "change owner to other user in same team" do
    choose("Someone in your team")
    select another_active_user.name, from: "investigation_select_team_member"
    click_button "Continue"

    fill_and_submit_change_owner_reason_form

    expect_confirmation_banner("Allegation owner changed to " + another_active_user.name)
    expect_page_to_show_case_owner(another_active_user)
    expect_activity_page_to_show_case_owner_changed_to(another_active_user)
  end

  scenario "change owner to your team" do
    choose user.team.name
    click_button "Continue"

    fill_and_submit_change_owner_reason_form

    expect_confirmation_banner("Allegation owner changed to " + user.team.name)
    expect_page_to_show_case_owner(user.team)
    expect_activity_page_to_show_case_owner_changed_to(user.team)
  end

  scenario "a case owned by someone else in another team can no longer have ownership changed by original owner" do
    choose("Someone else")
    select another_active_user_another_team.name, from: "investigation_select_someone_else"
    click_button "Continue"

    fill_and_submit_change_owner_reason_form

    expect_page_to_show_case_owner(another_active_user_another_team)
    expect_activity_page_to_show_case_owner_changed_to(another_active_user_another_team)

    click_link "Overview"
    expect(page).not_to have_link("Change owner")
  end

  def fill_and_submit_change_owner_reason_form
    fill_in "investigation_owner_rationale", with: "Test assign"
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
end
