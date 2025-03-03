require "rails_helper"

RSpec.describe "Adding supporting documents to a notification", :with_stubbed_antivirus, type: :request do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:notification) { create(:notification, :with_supporting_document, creator_user: user) }
  let(:document) { fixture_file_upload("testImage.png", "image/png") }
  let(:mailer) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:valid_params) { { document_form: { document: fixture_file_upload("testImage.png", "image/png"), title: "Test" } } }
  let(:invalid_params) { { document_form: { document: nil, title: "" } } }
  let(:controller) { Notifications::AddSupportingDocumentsController.new }

  before do
    sign_in(user)
    allow(NotifyMailer).to receive(:notification_created).and_return(mailer)
    allow(Notifications::AddSupportingDocumentsController).to receive(:new).and_return(controller)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET /notifications/:notification_pretty_id/add-supporting-documents" do
    context "when user can update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(true)
      end

      it "renders successfully" do
        get notification_add_supporting_documents_path(notification)
        expect(response).to have_http_status(:ok)
      end

      it "creates a new document form" do
        get notification_add_supporting_documents_path(notification)
        expect(assigns(:document_form)).to be_an_instance_of(DocumentForm)
      end
    end

    context "when user cannot update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(false)
      end

      it "returns forbidden status" do
        get notification_add_supporting_documents_path(notification)
        expect(response).to render_template("errors/forbidden")
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /notifications/:notification_pretty_id/add-supporting-documents" do
    context "when user can update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(true)
      end

      it "attaches a new document" do
        expect {
          post notification_add_supporting_documents_path(notification), params: valid_params
        }.to change { notification.documents.count }.by(1)
      end

      it "does not attach a document with invalid params" do
        expect {
          post notification_add_supporting_documents_path(notification), params: invalid_params
        }.not_to(change { notification.documents.count })
      end
    end

    context "when user cannot update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(false)
      end

      it "does not attach a document" do
        expect {
          post notification_add_supporting_documents_path(notification), params: valid_params
        }.not_to(change { notification.documents.count })
      end
    end
  end

  describe "DELETE /notifications/:notification_pretty_id/add-supporting-documents/:upload_id/remove" do
    context "when user can update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(true)
      end

      it "removes the document" do
        document = fixture_file_upload("testImage.png", "image/png")
        notification.documents.attach(document)
        document_id = notification.documents.first.id

        expect {
          delete remove_upload_notification_add_supporting_documents_path(notification, document_id)
        }.to change { notification.documents.count }.by(-1)
      end
    end

    context "when user cannot update the notification" do
      before do
        allow(controller).to receive(:user_can_edit?).and_return(false)
      end

      it "does not remove the document" do
        document = fixture_file_upload("testImage.png", "image/png")
        notification.documents.attach(document)
        document_id = notification.documents.first.id

        expect {
          delete remove_upload_notification_add_supporting_documents_path(notification, document_id)
        }.not_to(change { notification.documents.count })
      end
    end
  end
end
