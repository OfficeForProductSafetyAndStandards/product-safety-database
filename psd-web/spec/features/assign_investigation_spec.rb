require "rails_helper"

RSpec.feature "Assigning an investigation", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config  do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation, assignee: user) }

  let!(:another_active_user) { create(:user, :activated,name: "other user same team", organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }
  let!(:another_active_user_another_team) { create(:user, :activated,name: "another other user in another team", organisation: user.organisation, teams: [create(:team)]) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive,organisation: user.organisation, teams: [create(:team)]) }

  before { 
    
    sign_in(as_user: user) }

  scenario "only shows other active users" do
    visit "/cases/#{investigation.pretty_id}/assign/choose"

    expect(page).to have_css("#investigation_select_team_member option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#investigation_select_team_member option[value=\"#{another_inactive_user.id}\"]")

    expect(page).to have_css("#investigation_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
    expect(page).not_to have_css("#investigation_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
  end

  scenario " assign case to other user in same team" do
    visit "/cases/#{investigation.pretty_id}/assign/choose"
    choose('Someone in your team')
    select another_active_user.name, from: "investigation_select_team_member"
    click_button "Continue"
    fill_in "investigation_assignee_rationale",with: "Test assign"
    click_button "Confirm change"
    expect(page).to have_content(another_active_user.name)
  end

   scenario  "assign case to someone else in another team" do
     visit "/cases/#{investigation.pretty_id}/assign/choose"
     choose('Someone else')
     select another_active_user_another_team.name, from: "investigation_select_someone_else"
     click_button "Continue"
     fill_in "investigation_assignee_rationale",with: "Test assign"
     click_button "Confirm change"
     expect(page).to have_content(another_active_user_another_team.name)
   end

end
