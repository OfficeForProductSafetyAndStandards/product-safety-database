require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateSummary, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) { described_class.create(investigation: investigation, metadata: metadata) }

  let(:investigation) { create(:allegation) }
  let(:new_summary) { "new summary" }
  let(:old_summary) { "old summary" }

  let(:metadata) { described_class.build_metadata(new_summary, old_summary) }

  describe ".build_metadata" do
    it "returns a Hash of the arguments" do
      expect(metadata).to eq({
        summary: {
          new: new_summary,
          old: old_summary
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
      expect(activity.title(nil)).to eq("Allegation summary updated")
    end
  end
end
