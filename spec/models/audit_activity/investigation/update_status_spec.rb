require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateStatus, :with_stubbed_mailer do
  let(:notification) { create(:allegation, is_closed: false) }
  let(:metadata) { described_class.build_metadata(notification, rationale) }
  let(:rationale) { "Test" }

  before do
    # Notification changes must be saved for the metadata to build correctly
    notification.is_closed = true
    notification.save!
  end

  describe ".build_metadata" do
    it "returns a Hash of the arguments" do
      expect(metadata).to eq({
        updates: {
          "is_closed" => [false, true]
        },
        rationale:
      })
    end
  end
end
