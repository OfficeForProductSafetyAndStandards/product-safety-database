require "rails_helper"

RSpec.describe Notifications::AddSupportingDocumentsController, :with_stubbed_antivirus, type: :controller do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:notification) { create(:supporting_document_notification, creator_user: user) }
  let(:document) { fixture_file_upload("testImage.png", "image/png") }
  let(:policy) { instance_double(InvestigationPolicy, update?: true) }
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
    sign_in(user)
    allow(notification).to receive(:can_be_updated?).and_return(true)
    allow(NotifyMailer).to receive(:notification_created).and_return(mailer)
    allow(InvestigationPolicy).to receive(:new).and_return(policy)
  end

  describe "GET #show" do
    context "when user can update the notification" do
      it "renders the add_supporting_documents template" do
        get :show, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to render_template("add_supporting_documents")
      end

      it "creates a new document form" do
        get :show, params: { notification_pretty_id: notification.pretty_id }
        expect(assigns(:document_form)).to be_an_instance_of(DocumentForm)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "returns forbidden status" do
        get :show, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to render_template("errors/forbidden")
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #update" do
    context "when user can update the notification" do
      it "attaches a new document" do
        expect {
          post :update, params: valid_params
        }.to change { notification.documents.count }.by(1)
      end

      it "does not attach a document with invalid params" do
        expect {
          post :update, params: invalid_params
        }.not_to(change { notification.documents.count })
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "does not attach a document" do
        expect {
          post :update, params: valid_params
        }.not_to(change { notification.documents.count })
      end
    end
  end

  describe "DELETE #remove_upload" do
    context "when user can update the notification" do
      it "removes the document" do
        document = fixture_file_upload("testImage.png", "image/png")
        notification.documents.attach(document)
        document_id = notification.documents.first.id

        expect {
          delete :remove_upload, params: { notification_pretty_id: notification.pretty_id, upload_id: document_id }
        }.to change { notification.documents.count }.by(-1)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "does not remove the document" do
        document = fixture_file_upload("testImage.png", "image/png")
        notification.documents.attach(document)
        document_id = notification.documents.first.id

        expect {
          delete :remove_upload, params: { notification_pretty_id: notification.pretty_id, upload_id: document_id }
        }.not_to(change { notification.documents.count })
      end
    end
  end
end
