require "rails_helper"

RSpec.describe "Editing a collaborator for a notification", :with_stubbed_mailer, :with_stubbed_opensearch, type: :request do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

  let(:team) { create(:team) }
  let(:notification) { create(:notification, creator: user) }
  let(:edit_access_collaboration) do
    create(:collaboration_edit_access, investigation: notification, collaborator: team, added_by_user: user)
  end

  before do
    edit_access_collaboration
    sign_in user
  end

  context "when editing" do
    context "with owner collaboration" do
      before do
        get edit_investigation_collaborator_path(notification.pretty_id, notification.owner_team_collaboration.id)
      end

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when deleting" do
    let(:permission_level) { EditNotificationCollaboratorForm::PERMISSION_LEVEL_DELETE }
    let(:message) { "" }
    let(:include_message) { "false" }

    let(:params) do
      { edit_notification_collaborator_form: {
        permission_level:,
        message:,
        include_message:,
      } }
    end

    let(:do_request) do
      put investigation_collaborator_path(notification.pretty_id, edit_access_collaboration.id), params:
    end

    context "when successful" do
      it "removes collaborator" do
        expect { do_request }.to change(Collaboration::Access::Edit, :count).from(3).to(2)
      end

      it "redirects back to the 'teams added to notification' page" do
        expect(do_request).to redirect_to(investigation_collaborators_path(notification))
      end

      it "displays proper flash message" do
        do_request
        expect(flash[:success]).to eq("#{team.name} has been removed from the notification")
      end
    end

    context "with missing params" do
      let(:include_message) { "true" }

      it "is not successful" do
        do_request
        expect(response).to render_template("collaborators/edit")
      end
    end

    context "with owner collaboration" do
      before do
        put investigation_collaborator_path(notification.pretty_id, notification.owner_team_collaboration.id), params:
      end

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the collaboration has already been deleted" do
      before do
        edit_access_collaboration.destroy!
      end

      it "redirects back to the 'teams added to case' page" do
        expect(do_request).to redirect_to(investigation_collaborators_path(notification))
      end
    end
  end

  context "when the user isn't part of the team assigned" do
    let(:creator) { create(:user) }
    let(:notification) { create(:notification, creator:) }

    before do
      ChangeNotificationOwner.call!(notification:, owner: creator.team, user: creator)
    end

    it "responds with a 403 (Forbidden) status code on update" do
      put investigation_collaborator_path(notification.pretty_id, team.id)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
