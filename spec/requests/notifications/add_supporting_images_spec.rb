require "rails_helper"

RSpec.describe "Supporting Images Management", :with_stubbed_antivirus, :with_stubbed_mailer, :with_test_queue_adapter, type: :request do
  let(:user) { create(:user, :activated) }
  let(:notification) { create(:notification, creator: user, pretty_id: "2403-0001") }
  let(:image_file) { fixture_file_upload("testImage.png", "image/png") }

  before do
    sign_in(user)
    # Ensure notification is persisted and associations are loaded before tests
    # This prevents potential race conditions in the test environment
    notification.reload
  end

  def upload_test_image
    post notification_add_supporting_images_path(notification_pretty_id: notification.pretty_id),
         params: { image_upload: { file_upload: image_file } }
    notification.reload.image_uploads.first
  end

  describe "GET /notifications/:pretty_id/add-supporting-images" do
    it "renders the upload form" do
      get notification_add_supporting_images_path(notification_pretty_id: notification.pretty_id)
      expect(response).to render_template("notifications/add_supporting_images/add_supporting_images")
    end
  end

  describe "POST /notifications/:pretty_id/add-supporting-images" do
    it "successfully uploads an image" do
      post notification_add_supporting_images_path(notification_pretty_id: notification.pretty_id),
           params: { image_upload: { file_upload: image_file } }

      expect(notification.reload.image_uploads.count).to eq(1)
      expect(flash[:success]).to eq("Supporting image uploaded successfully")
    end
  end

  describe "DELETE /notifications/:pretty_id/add-supporting-images/:upload_id/remove" do
    it "successfully removes an image" do
      image_upload = upload_test_image

      delete remove_upload_notification_add_supporting_images_path(
        notification_pretty_id: notification.pretty_id,
        upload_id: image_upload.id
      )

      expect(notification.reload.image_uploads).to be_empty
      expect(flash[:success]).to eq("Supporting image removed successfully")
    end
  end
end
