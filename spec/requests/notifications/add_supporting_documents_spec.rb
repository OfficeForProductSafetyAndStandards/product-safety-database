require "rails_helper"

RSpec.describe "Adding supporting documents to a notification", :with_stubbed_antivirus, type: :request do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:notification) { create(:supporting_document_notification, creator_user: user) }
  let(:document_upload) { create(:document_upload, upload_model: notification) }
  let(:policy) { instance_double(InvestigationPolicy, update?: true) }
  let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:valid_params) { { document_upload: { file_upload: fixture_file_upload("testImage.png", "image/png"), title: "Test" } } }
  let(:invalid_params) { { document_upload: { file_upload: nil, title: "" } } }

  before do
    sign_in(user)
    allow(notification).to receive(:can_be_updated?).and_return(true)
    allow(NotifyMailer).to receive(:notification_created).and_return(mailer)
    allow(InvestigationPolicy).to receive(:new).and_return(policy)
  end

  describe "GET /notifications/:notification_pretty_id/add-supporting-documents" do
    context "when user can update the notification" do
      it "renders successfully" do
        get notification_add_supporting_documents_path(notification)
        expect(response).to have_http_status(:ok)
      end

      it "creates a new document upload" do
        get notification_add_supporting_documents_path(notification)
        expect(assigns(:document_upload)).to be_a_new(DocumentUpload)
      end
    end

    context "when user cannot update the notification" do
      let(:policy) { instance_double(InvestigationPolicy, update?: false) }

      before do
        allow(notification).to receive(:can_be_updated?).and_return(false)
      end

      it "redirects to the notification page" do
        get notification_add_supporting_documents_path(notification)
        expect(response).to redirect_to(notification_path(notification))
      end
    end
  end

  describe "POST /notifications/:notification_pretty_id/add-supporting-documents" do
    context "when user can update the notification" do
      it "creates a new document upload" do
        expect {
          post notification_add_supporting_documents_path(notification), params: valid_params
        }.to change(DocumentUpload, :count).by(1)
      end

      it "does not create a document upload with invalid params" do
        expect {
          post notification_add_supporting_documents_path(notification), params: invalid_params
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
          post notification_add_supporting_documents_path(notification), params: valid_params
        }.not_to change(DocumentUpload, :count)
      end
    end
  end

  describe "DELETE /notifications/:notification_pretty_id/add-supporting-documents/:upload_id/remove" do
    context "when user can update the notification" do
      it "removes the document upload" do
        document_upload.update!(upload_model: notification)
        notification.document_upload_ids << document_upload.id
        notification.save!

        expect {
          delete remove_upload_notification_add_supporting_documents_path(notification, document_upload)
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
          delete remove_upload_notification_add_supporting_documents_path(notification, document_upload)
        }.not_to change(DocumentUpload, :count)
      end
    end
  end
end
