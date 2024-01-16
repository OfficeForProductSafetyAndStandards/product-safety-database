RSpec.describe "Changing case summary", :with_stubbed_mailer, type: :request do
  let(:notification) do
    create(
      :notification,
      description: "old summary",
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

  let(:user_from_owner_team) { create(:user, :activated) }
  let(:user_from_collaborator_team) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  describe "Accessing the form" do
    before do
      sign_in user
      get edit_investigation_summary_path(notification)
    end

    context "when the user belongs to the case owner’s team" do
      let(:user) { user_from_owner_team }

      it "returns a success status code" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user belongs to the a collaborating team" do
      let(:user) { user_from_collaborator_team }

      it "returns a success status code" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user belongs a team not involved with the case" do
      let(:user) { other_user }

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Updating the summary" do
    before do
      sign_in user
      patch investigation_summary_path(notification),
            params: {
              change_notification_summary_form: { summary: "test" }
            }
    end

    context "when the user belongs to the case owner’s team" do
      let(:user) { user_from_owner_team }

      it "updates the investigation and redirects to the investigation page" do
        aggregate_failures do
          expect(notification.reload.description).to eq("test")
          expect(response).to redirect_to(investigation_path(notification))
        end
      end
    end

    context "when the user belongs to the a collaborating team" do
      let(:user) { user_from_collaborator_team }

      it "updates the investigation and redirects to the investigation page" do
        aggregate_failures do
          expect(notification.reload.description).to eq("test")
          expect(response).to redirect_to(investigation_path(notification))
        end
      end
    end

    context "when the user belongs a team not involved with the case" do
      let(:user) { other_user }

      it "returns a forbidden status code and doesn’t update the investigation" do
        aggregate_failures do
          expect(response).to have_http_status(:forbidden)
          expect(notification.reload.description).to eq("old summary")
        end
      end
    end
  end
end
