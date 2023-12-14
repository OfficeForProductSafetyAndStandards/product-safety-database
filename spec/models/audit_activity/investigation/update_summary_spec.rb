require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateSummary, :with_stubbed_mailer do
  subject(:activity) { described_class.create(investigation:, metadata:) }

  let(:investigation) { create(:allegation, description: old_summary) }
  let(:metadata) { described_class.build_metadata(investigation) }
  let(:new_summary) { "new summary" }
  let(:old_summary) { "old summary" }

  before do
    # Investigation changes must be saved for the metadata to build correctly
    investigation.description = new_summary
    investigation.save!
  end

  describe ".build_metadata" do
    it "returns a Hash of the arguments" do
      expect(metadata).to eq({
        updates: {
          "description" => ["old summary", "new summary"]
        }
      })
    end
  end

  describe "#new_summary" do
    it "returns the new summary from metadata" do
      expect(activity.new_summary).to eq(new_summary)
    end
  end

  describe "#title" do
    it "returns a String" do
      expect(activity.title(nil)).to eq("Case summary updated")
    end
  end
end
