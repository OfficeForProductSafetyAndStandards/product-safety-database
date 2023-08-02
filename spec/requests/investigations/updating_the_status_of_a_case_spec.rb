require "rails_helper"

RSpec.describe "Updating the status of a case", :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:user_from_owner_team) { create(:user, :activated) }
  let(:user_from_collaborator_team) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  let(:investigation) do
    create(
      :allegation,
      is_closed: false,
      creator: user_from_owner_team,
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
      patch close_investigation_status_path(investigation),
            params: {
              change_case_status_form: { rationale: "Test" }
            }
    end

    context "when status is changed to closed" do
      it "updates the investigation and redirects to the investigation page", :aggregate_failures do
        expect(investigation.reload.is_closed).to be true
        expect(investigation.date_closed).not_to be nil
        expect(response).to redirect_to(investigation_path(investigation))
      end
    end

    context "when case is re-opened" do
      before do
        patch reopen_investigation_status_path(investigation),
              params: {
                change_case_status_form: { rationale: "Test" }
              }
      end

      it "updates the investigation and redirects to the investigation page", :aggregate_failures do
        expect(investigation.reload.is_closed).to be false
        expect(investigation.date_closed).to be nil
        expect(response).to redirect_to(investigation_path(investigation))
      end
    end
  end

  context "when the user belongs to the a collaborating team", :with_errors_rendered do
    before do
      sign_in user_from_collaborator_team
      patch close_investigation_status_path(investigation),
            params: {
              change_case_status_form: { rationale: "Test" }
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
      patch close_investigation_status_path(investigation),
            params: {
              change_case_status_form: { rationale: "Test" }
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
