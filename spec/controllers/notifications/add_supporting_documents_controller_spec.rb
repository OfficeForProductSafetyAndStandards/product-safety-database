require "rails_helper"

RSpec.describe Notifications::AddSupportingDocumentsController, :with_stubbed_antivirus, type: :controller do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:notification) { create(:supporting_document_notification, creator_user: user) }
  let(:document_upload) { create(:document_upload, upload_model: notification) }
  let(:policy) { instance_double(InvestigationPolicy, update?: true) }
  let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:valid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      document_upload: {
        file_upload: fixture_file_upload("testImage.png", "image/png"),
        title: "Test"
      }
    }
  end
  let(:invalid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      document_upload: {
        file_upload: nil,
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

      it "creates a new document upload" do
        get :show, params: { notification_pretty_id: notification.pretty_id }
        expect(assigns(:document_upload)).to be_a_new(DocumentUpload)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "redirects to the notification page" do
        get :show, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to redirect_to(notification_path(notification))
      end
    end
  end

  describe "POST #update" do
    context "when user can update the notification" do
      it "creates a new document upload" do
        expect {
          post :update, params: valid_params
        }.to change(DocumentUpload, :count).by(1)
      end

      it "does not create a document upload with invalid params" do
        expect {
          post :update, params: invalid_params
        }.not_to change(DocumentUpload, :count)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "does not create a document upload" do
        expect {
          post :update, params: valid_params
        }.not_to change(DocumentUpload, :count)
      end
    end
  end

  describe "DELETE #remove_upload" do
    context "when user can update the notification" do
      it "removes the document upload" do
        document_upload.update!(upload_model: notification)
        notification.document_upload_ids << document_upload.id
        notification.save!

        expect {
          delete :remove_upload, params: { notification_pretty_id: notification.pretty_id, upload_id: document_upload.id }
        }.to change(DocumentUpload, :count).by(-1)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "does not remove the document upload" do
        document_upload # Create the document upload
        notification.document_upload_ids << document_upload.id
        notification.save!

        expect {
          delete :remove_upload, params: { notification_pretty_id: notification.pretty_id, upload_id: document_upload.id }
        }.not_to change(DocumentUpload, :count)
      end
    end
  end
end
