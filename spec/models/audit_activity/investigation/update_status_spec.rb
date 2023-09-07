require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateStatus, :with_stubbed_mailer do
  let(:investigation) { create(:allegation, is_closed: false) }
  let(:metadata) { described_class.build_metadata(investigation, rationale) }
  let(:rationale) { "Test" }

  before do
    # Investigation changes must be saved for the metadata to build correctly
    investigation.is_closed = true
    investigation.save!
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
