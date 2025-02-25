require "rails_helper"

RSpec.describe Notifications::AddSupportingDocumentsController, :with_stubbed_antivirus, :with_stubbed_mailer, type: :controller do
  let(:creator_user) { create(:user, :activated, :opss_user, team: creator_team) }
  let(:owner_user) { create(:user, :activated, :opss_user, team: owner_team) }
  let(:other_user) { create(:user, :activated, :opss_user) }
  let(:creator_team) { create(:team) }
  let(:owner_team) { create(:team) }
  let(:edit_access_team) { create(:team) }
  let(:read_only_team) { create(:team) }
  let(:notification) do
    create(:notification,
           creator: creator_user,
           creator_team: creator_team,
           edit_access_teams: [edit_access_team],
           read_only_teams: [read_only_team]).tap do |n|
      n.owner_user = owner_user
      n.owner_team = owner_team
      n.save!
    end
  end
  let(:document) { fixture_file_upload("testImage.png", "image/png") }
  let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:valid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      document_form: {
        document: fixture_file_upload("testImage.png", "image/png"),
        title: "Test"
      }
    }
  end
  let(:invalid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      document_form: {
        document: nil,
        title: ""
      }
    }
  end

  before do
    sign_in(creator_user)
    allow(NotifyMailer).to receive(:notification_created).and_return(mailer)
  end

  shared_examples "forbidden access" do
    it "returns forbidden status" do
      get :show, params: { notification_pretty_id: notification.pretty_id }
      expect(response).to have_http_status(:forbidden)
    end

    it "prevents document upload" do
      expect {
        post :update, params: valid_params
      }.not_to(change { notification.documents.count })
    end

    it "prevents document removal" do
      notification.documents.attach(document)
      document_id = notification.documents.first.id

      expect {
        delete :remove_upload, params: { notification_pretty_id: notification.pretty_id, upload_id: document_id }
      }.not_to(change { notification.documents.count })
    end
  end

  shared_examples "allowed access" do
    it "allows viewing the form" do
      get :show, params: { notification_pretty_id: notification.pretty_id }
      expect(response).to render_template("add_supporting_documents")
    end

    it "allows document upload" do
      expect {
        post :update, params: valid_params
      }.to change { notification.documents.count }.by(1)
    end

    let(:notification_with_document) do
      create(:notification, :with_supporting_document,
             creator: creator_user,
             creator_team: creator_team,
             edit_access_teams: [edit_access_team],
             read_only_teams: [read_only_team]).tap do |n|
        n.owner_user = owner_user
        n.owner_team = owner_team
        n.save!
      end
    end

    it "allows document removal" do
      document_id = notification_with_document.documents.first.id

      expect {
        delete :remove_upload, params: { notification_pretty_id: notification_with_document.pretty_id, upload_id: document_id }
      }.to change { notification_with_document.documents.count }.by(-1)
    end
  end

  context "when user is the creator" do
    include_examples "allowed access"
  end

  context "when user is the owner" do
    before { sign_in(owner_user) }

    include_examples "allowed access"
  end

  context "when user is in the creator team" do
    before { sign_in(create(:user, :activated, team: creator_team)) }

    include_examples "allowed access"
  end

  context "when user is in the owner team" do
    before { sign_in(create(:user, :activated, team: owner_team)) }

    include_examples "allowed access"
  end

  context "when user is in a team with edit access" do
    before { sign_in(create(:user, :activated, team: edit_access_team)) }

    include_examples "allowed access"
  end

  context "when user is in a team with read-only access" do
    before { sign_in(create(:user, :activated, team: read_only_team)) }

    include_examples "forbidden access"
  end

  context "when user has no access" do
    before { sign_in(other_user) }

    include_examples "forbidden access"
  end

  context "with invalid notification ID" do
    it "returns 404 status" do
      get :show, params: { notification_pretty_id: "nonexistent" }
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when user is not signed in" do
    before { sign_out(creator_user) }

    it "redirects to sign in page" do
      get :show, params: { notification_pretty_id: notification.pretty_id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
