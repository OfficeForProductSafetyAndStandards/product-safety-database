require "rails_helper"

describe "Assigning an investigation", type: :request, with_keycloak_config: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }
  let(:investigation) { create(:allegation) }

  let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }
  let!(:another_active_user_another_team) { create(:user, :activated, organisation: user.organisation, teams: [create(:team)]) }
  let!(:another_inactive_user_another_team) { create(:user, :inactive, organisation: user.organisation, teams: [create(:team)]) }

  before { sign_in(as_user: user) }

  context "when the user wishes to assign to another user in the same team" do
    before { get "/cases/#{investigation.pretty_id}/assign/choose" }

    it "only shows other active users" do
      expect(response.body).to have_css("#investigation_select_team_member option[value=\"#{another_active_user.id}\"]")
      expect(response.body).not_to have_css("#investigation_select_team_member option[value=\"#{another_inactive_user.id}\"]")
    end
  end

  context "when the user wishes to assign to someone else" do
    before { get "/cases/#{investigation.pretty_id}/assign/choose" }

    it "only shows other active users" do
      expect(response.body).to have_css("#investigation_select_someone_else option[value=\"#{another_active_user_another_team.id}\"]")
      expect(response.body).not_to have_css("#investigation_select_someone_else option[value=\"#{another_inactive_user_another_team.id}\"]")
    end
  end
end
