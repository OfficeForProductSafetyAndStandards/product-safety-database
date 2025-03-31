require "rails_helper"

RSpec.describe Notifications::RecordACorrectiveActionController, type: :routing do
  describe "routing" do
    it "routes to #new" do
      expect(get: "/notifications/1/add/record_a_corrective_action")
        .to route_to(
          controller: "notifications/record_a_corrective_action",
          action: "new",
          notification_pretty_id: "1"
        )
    end

    it "routes to #create" do
      expect(post: "/notifications/1/add/record_a_corrective_action")
        .to route_to(
          controller: "notifications/record_a_corrective_action",
          action: "create",
          notification_pretty_id: "1"
        )
    end

    it "routes to #edit" do
      expect(get: "/notifications/1/edit/record_a_corrective_action/2")
        .to route_to(
          controller: "notifications/record_a_corrective_action",
          action: "edit",
          notification_pretty_id: "1",
          id: "2"
        )
    end

    it "routes to #update via PUT" do
      expect(put: "/notifications/1/edit/record_a_corrective_action/2")
        .to route_to(
          controller: "notifications/record_a_corrective_action",
          action: "update",
          notification_pretty_id: "1",
          id: "2"
        )
    end

    it "routes to #update via PATCH" do
      expect(patch: "/notifications/1/edit/record_a_corrective_action/2")
        .to route_to(
          controller: "notifications/record_a_corrective_action",
          action: "update",
          notification_pretty_id: "1",
          id: "2"
        )
    end
  end
end
