require "rails_helper"

RSpec.describe "Adding a collaborator to a case", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, teams: [user_team]) }

  context "when the collaborator params are valid" do
    let(:message) { "Thanks for collaborating on this case" }
    let(:investigation) { create(:investigation, owner: user) }
    let(:other_team) { create(:team) }

    before do
      sign_in user

      post investigation_collaborators_path(investigation.pretty_id),
           params: {
             collaborator: {
               include_message: "true",
               message: message,
               team_id: other_team.id
             }
           }
    end

    it "redirects back to the 'teams added to case' page" do
      expect(response).to redirect_to(investigation_collaborators_path(investigation))
    end

    it "adds the team as a collaborator to the case" do
      expect(investigation.teams).to include(other_team)
    end

    it "includes the message in the collaborator record" do
      expect(investigation.collaborators.first.message).to eql(message)
    end

    it "associates the collaborator with the user who added the team" do
      expect(investigation.collaborators.first.added_by_user).to eql(user)
    end
  end

  context "when the collaborator params are invalid" do
    let(:message) { "Thanks for collaborating on this case" }
    let(:investigation) { create(:investigation, owner: user) }
    let(:other_team) { create(:team) }

    before do
      sign_in user

      post investigation_collaborators_path(investigation.pretty_id),
           params: {
             collaborator: {
               include_message: "true",
               message: "",
               team_id: ""
             }
           }
    end

    it "re-renders the template" do
      expect(response).to render_template("collaborators/new")
    end
  end

  context "when trying to add a team who is already a collaborator" do
    let(:existing_collaborator_team) { create(:team) }
    let(:investigation) {
      create(:investigation,
             owner: user,
             collaborators: [
               create(:collaborator,
                      team: existing_collaborator_team,
                      include_message: false,
                      added_by_user: user)
             ])
    }


    before do
      sign_in user

      post investigation_collaborators_path(investigation.pretty_id),
           params: {
             collaborator: {
               include_message: "false",
               team_id: existing_collaborator_team.id
             }
           }
    end

    it "redirects back to the 'teams added to case' page" do
      expect(response).to redirect_to(investigation_collaborators_path(investigation))
    end
  end

  context "when the user isn't part of the team that is the case owner", :with_errors_rendered do
    let(:investigation) { create(:investigation, owner: create(:team)) }

    before do
      sign_in user
      post investigation_collaborators_path(investigation.pretty_id)
    end

    it "responds with a 403 (Forbidden) status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
