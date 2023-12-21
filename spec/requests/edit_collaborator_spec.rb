require "rails_helper"

RSpec.describe "Editing a collaborator for a case", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

  let(:team) { create(:team) }
  let(:investigation) { create(:allegation, creator: user) }
  let(:edit_access_collaboration) do
    create(:collaboration_edit_access, investigation:, collaborator: team, added_by_user: user)
  end

  before do
    edit_access_collaboration
    sign_in user
  end

  context "when editing" do
    context "with owner collaboration" do
      before do
        get edit_investigation_collaborator_path(investigation.pretty_id, investigation.owner_team_collaboration.id)
      end

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when deleting" do
    let(:permission_level) { EditCaseCollaboratorForm::PERMISSION_LEVEL_DELETE }
    let(:message) { "" }
    let(:include_message) { "false" }

    let(:params) do
      { edit_case_collaborator_form: {
        permission_level:,
        message:,
        include_message:,
      } }
    end

    let(:do_request) do
      put investigation_collaborator_path(investigation.pretty_id, edit_access_collaboration.id), params:
    end

    context "when successful" do
      it "removes collaborator" do
        expect { do_request }.to change(Collaboration::Access::Edit, :count).from(3).to(2)
      end

      it "redirects back to the 'teams added to case' page" do
        expect(do_request).to redirect_to(investigation_collaborators_path(investigation))
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
        put investigation_collaborator_path(investigation.pretty_id, investigation.owner_team_collaboration.id), params:
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
        expect(do_request).to redirect_to(investigation_collaborators_path(investigation))
      end
    end
  end

  context "when the user isn't part of the team assigned" do
    let(:creator) { create(:user) }
    let(:investigation) { create(:allegation, creator:) }

    before do
      ChangeCaseOwner.call!(investigation:, owner: creator.team, user: creator)
    end

    it "responds with a 403 (Forbidden) status code on update" do
      put investigation_collaborator_path(investigation.pretty_id, team.id)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
