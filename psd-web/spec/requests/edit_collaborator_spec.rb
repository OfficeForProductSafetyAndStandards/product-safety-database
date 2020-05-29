require "rails_helper"

RSpec.describe "Editig a collaborator for a case", type: :request, with_stubbed_mailer: true, with_stubbed_elasticsearch: true do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

  let(:team) { create(:team) }
  let(:investigation) { create(:allegation, owner: user) }
  let(:edit_access_collaboration) do
    create(:collaboration_edit_access, investigation: investigation, collaborator: team, added_by_user: user)
  end

  before do
    edit_access_collaboration
    sign_in user
  end

  context "when deleting" do
    let(:permission_level) { EditInvestigationCollaboratorForm::PERMISSION_LEVEL_DELETE }
    let(:message) { "" }
    let(:include_message) { "false" }

    let(:params) do
      { edit_investigation_collaborator_form: {
        permission_level: permission_level,
        message: message,
        include_message: include_message,
      } }
    end

    let(:do_request) do
      put investigation_collaborator_path(investigation.pretty_id, team.id), params: params
    end

    context "when successful" do
      it "removes collaborator" do
        expect { do_request }.to change(Collaboration::EditAccess, :count).from(1).to(0)
      end

      it "redirects back to the 'teams added to case' page" do
        expect(do_request).to redirect_to(investigation_collaborators_path(investigation))
      end

      it "displays proper flash message" do
        do_request
        expect(flash[:success]).to eq("#{team.name} has been removed from the case")
      end
    end

    context "with missing params" do
      let(:include_message) { "true" }

      it "is not successful" do
        do_request
        expect(response).to render_template("collaborators/edit")
      end
    end
  end

  context "when the user isn't part of the team assigned", :with_errors_rendered do
    let(:investigation) { create(:allegation, owner: create(:team)) }

    it "responds with a 403 (Forbidden) status code on update" do
      put investigation_collaborator_path(investigation.pretty_id, team.id)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
