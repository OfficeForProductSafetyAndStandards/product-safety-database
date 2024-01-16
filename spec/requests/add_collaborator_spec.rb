RSpec.describe "Adding a collaborator to a notification", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

  context "when the collaborator params are valid" do
    let(:message) { "Thanks for collaborating on this notification" }
    let(:notification) { create(:notification, creator: user) }
    let(:other_team) { create(:team) }

    before do
      sign_in user

      post investigation_collaborators_path(notification.pretty_id),
           params: {
             add_team_to_notification_form: {
               include_message: "true",
               message:,
               team_id: other_team.id,
               permission_level: "edit"
             }
           }
    end

    it "redirects back to the 'teams added to case' page" do
      expect(response).to redirect_to(investigation_collaborators_path(notification))
    end

    it "adds the team as a collaborator to the case" do
      expect(notification.teams_with_edit_access).to include(other_team)
    end

    it "includes the message in the collaborator record" do
      expect(notification.edit_access_collaborations.find_by!(collaborator: other_team).message).to eq(message)
    end

    it "associates the collaborator with the user who added the team" do
      expect(notification.edit_access_collaborations.find_by!(collaborator: other_team).added_by_user).to eq(user)
    end
  end

  context "when the collaborator params are invalid" do
    let(:message) { "Thanks for collaborating on this case" }
    let(:notification) { create(:notification, creator: user) }
    let(:other_team) { create(:team) }

    before do
      sign_in user

      post investigation_collaborators_path(notification.pretty_id),
           params: {
             add_team_to_notification_form: {
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
    let(:notification) do
      create(
        :allegation,
        creator: user,
        edit_access_collaborations: [
          create(
            :collaboration_edit_access,
            collaborator: existing_collaborator_team,
            added_by_user: user
          )
        ]
      )
    end

    before do
      sign_in user

      post investigation_collaborators_path(notification.pretty_id),
           params: {
             add_team_to_notification_form: {
               include_message: "false",
               team_id: existing_collaborator_team.id
             }
           }
    end

    it "returns an error" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when the user isn't part of the team that is the case owner" do
    let(:notification) { create(:notification) }

    before do
      ChangeNotificationOwner.call!(notification:, owner: create(:team), user:)
      sign_in user
      post investigation_collaborators_path(notification.pretty_id)
    end

    it "responds with a 403 (Forbidden) status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
