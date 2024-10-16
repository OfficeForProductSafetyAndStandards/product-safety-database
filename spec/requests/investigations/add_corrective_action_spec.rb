require "rails_helper"

RSpec.describe "Adding a corrective action to a case", :with_stubbed_mailer, :with_stubbed_opensearch, type: :request do
  let(:user_from_owner_team) { create(:user, :activated) }
  let(:user_from_team_with_read_only_access) { create(:user, :activated) }
  let(:user_from_team_with_edit_access) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  let(:investigation) do
    create(
      :allegation,
      is_closed: false,
      creator: user_from_owner_team,
      edit_access_collaborations: [
        create(
          :collaboration_edit_access,
          collaborator: user_from_team_with_edit_access.team
        )
      ],
      read_only_collaborations: [
        create(
          :read_only_collaboration,
          collaborator: user_from_team_with_read_only_access.team
        )
      ]
    )
  end

  context "when the user is from a team with read-only access" do
    before do
      sign_in user_from_team_with_read_only_access
      post investigation_corrective_actions_path(investigation.pretty_id)
    end

    it "returns a forbidden status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the user is from a team not associated with the case" do
    before do
      sign_in other_user
      post investigation_corrective_actions_path(investigation.pretty_id)
    end

    it "returns a forbidden status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
