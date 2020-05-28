require "rails_helper"

RSpec.describe "Changing the owner of a case", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:user_from_owner_team) { create(:user, :activated) }
  let(:user_from_collaborator_team) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  let(:investigation) do
    create(
      :allegation,
      is_closed: false,
      owner: user_from_owner_team.team,
      edit_access_collaborations: [
        create(
          :collaboration_edit_access,
          collaborator: user_from_collaborator_team.team
        )
      ]
    )
  end

  context "when the user is from the case owner’s team" do
    before do
      sign_in user_from_owner_team
      User.current = user_from_owner_team
      put investigation_ownership_path(investigation, "select-owner"),
          params: {
            investigation: {
              owner_id: "someone_else",
              select_someone_else: other_user.id
            }
          }
    end

    it "redirects to the confirm page" do
      expect(response).to redirect_to(investigation_ownership_path(investigation, "confirm"))
    end
  end

  context "when the user is from a collaborating team", :with_errors_rendered do
    before do
      sign_in user_from_collaborator_team
      put investigation_ownership_path(investigation, "select-owner"),
          params: {
            investigation: {
              owner_id: "someone_else",
              select_someone_else: other_user.id
            }
          }
    end

    it "returns a forbidden status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the user is not involved with the case", :with_errors_rendered do
    before do
      sign_in other_user
      put investigation_ownership_path(investigation, "select-owner"),
          params: {
            investigation: {
              owner_id: "someone_else",
              select_someone_else: other_user.id
            }
          }
    end

    it "returns a forbidden status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
