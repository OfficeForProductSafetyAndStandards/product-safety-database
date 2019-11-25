require "rails_helper"

RSpec.feature "Assigning an investigation", type: :feature, with_keycloak_config: true, with_stubbed_elasticsearch: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation) }

  let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }
  let!(:another_active_user_another_team) { create(:user, :activated, organisation: user.organisation, teams: [create(:team)]) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive, organisation: user.organisation, teams: [create(:team)]) }

  before { sign_in(as_user: user) }

  scenario "only shows other active users" do
    visit "/cases/#{investigation.pretty_id}/assign/choose"

    expect(page).to have_css("#investigation_select_team_member option[value=\"#{another_active_user.id}\"]")
    expect(page).not_to have_css("#investigation_select_team_member option[value=\"#{another_inactive_user.id}\"]")

    expect(page).to have_css("#investigation_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
    expect(page).not_to have_css("#investigation_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
  end
end
