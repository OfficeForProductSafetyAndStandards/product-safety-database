require "rails_helper"

RSpec.describe "Updating the status of a case", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :request do
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

  context "when the user belongs to the case owner’s team" do
    before do
      sign_in user_from_owner_team
      User.current = user_from_owner_team
      patch status_investigation_path(investigation),
            params: {
              investigation: { is_closed: "true", status_rationale: "Test" }
            }
    end

    it "updates the investigation and redirects to the investigation page" do
      aggregate_failures do
        expect(investigation.reload.is_closed).to be true
        expect(response).to redirect_to(investigation_path(investigation))
      end
    end
  end

  context "when the user belongs to the a collaborating team", :with_errors_rendered do
    before do
      sign_in user_from_collaborator_team
      User.current = user_from_collaborator_team
      patch status_investigation_path(investigation),
            params: {
              investigation: { is_closed: "true", status_rationale: "Test" }
            }
    end

    it "returns a forbidden status code and doesn’t update the investigation" do
      aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(investigation.reload.is_closed).to be false
      end
    end
  end

  context "when the user belongs a team not involved with the case", :with_errors_rendered do
    before do
      sign_in other_user
      User.current = other_user
      patch status_investigation_path(investigation),
            params: {
              investigation: { is_closed: "true", status_rationale: "Test" }
            }
    end

    it "returns a forbidden status code and doesn’t update the investigation" do
      aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(investigation.reload.is_closed).to be false
      end
    end
  end
end
