require "rails_helper"

RSpec.describe "routes for add_supporting_images", type: :routing do
  let(:notification_id) { "2501-0042" }
  let(:upload_id) { "5" }

  describe "GET /notifications/:notification_pretty_id/add-supporting-images" do
    it "routes to add_supporting_images#show" do
      expect(get: "/notifications/#{notification_id}/add-supporting-images").to route_to(
        controller: "notifications/add_supporting_images",
        action: "show",
        notification_pretty_id: notification_id
      )
    end
  end

  describe "POST /notifications/:notification_pretty_id/create/add-supporting-images" do
    it "routes to add_supporting_images#update" do
      expect(post: "/notifications/#{notification_id}/add-supporting-images").to route_to(
        controller: "notifications/add_supporting_images",
        action: "update",
        notification_pretty_id: notification_id
      )
    end
  end

  describe "GET /notifications/:notification_pretty_id/add-supporting-images/:upload_id/remove" do
    it "routes to add_supporting_images#remove_upload" do
      expect(get: "/notifications/#{notification_id}/add-supporting-images/#{upload_id}/remove").to route_to(
        controller: "notifications/add_supporting_images",
        action: "remove_upload",
        notification_pretty_id: notification_id,
        upload_id: upload_id
      )
    end
  end

  describe "DELETE /notifications/:notification_pretty_id/add-supporting-images/:upload_id/remove" do
    it "routes to add_supporting_images#remove_upload" do
      expect(delete: "/notifications/#{notification_id}/add-supporting-images/#{upload_id}/remove").to route_to(
        controller: "notifications/add_supporting_images",
        action: "remove_upload",
        notification_pretty_id: notification_id,
        upload_id: upload_id
      )
    end
  end

  describe "path helpers" do
    it "generates the correct paths" do
      expect(notification_add_supporting_images_path(notification_id))
        .to eq("/notifications/#{notification_id}/add-supporting-images")

      expect(remove_upload_notification_add_supporting_images_path(notification_id, upload_id))
        .to eq("/notifications/#{notification_id}/add-supporting-images/#{upload_id}/remove")
    end
  end
end
