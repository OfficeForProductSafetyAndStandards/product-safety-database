require "rails_helper"

RSpec.describe TableAccessibilityHelper do
  let(:mail_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:notification) { create(:notification) }

  before do
    allow(NotifyMailer).to receive(:notification_created).and_return(mail_message)
  end

  describe "#notification_screen_reader_description" do
    it "includes notification number" do
      expect(helper.notification_screen_reader_description(notification))
        .to include("Notification number: #{notification.pretty_id}")
    end

    context "when on search cases page" do
      it "includes owner information" do
        expect(helper.notification_screen_reader_description(notification))
          .to include("Owner:")
      end
    end

    context "when on team cases page" do
      it "includes creation date" do
        expect(helper.notification_screen_reader_description(notification, "team_cases"))
          .to include("Created:")
      end
    end
  end

  describe "#screen_reader_description_id" do
    it "generates a unique id" do
      expect(helper.screen_reader_description_id("test", notification))
        .to eq("description-test-#{notification.id}")
    end
  end

  describe "#accessible_table_header_attributes" do
    it "returns correct attributes" do
      attributes = helper.accessible_table_header_attributes("Test Header")
      expect(attributes[:scope]).to eq("col")
      expect(attributes[:"aria-label"]).to eq("Test Header")
    end
  end
end
