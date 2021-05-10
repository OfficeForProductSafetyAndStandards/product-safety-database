require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateVisibility, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:investigation) { create(:allegation, is_private: false) }
  let(:metadata) { described_class.build_metadata(investigation, rationale) }
  let(:rationale) { "Test" }

  before do
    # Investigation changes must be saved for the metadata to build correctly
    investigation.is_private = true
    investigation.save!
  end

  describe ".build_metadata" do
    it "returns a Hash of the arguments" do
      expect(metadata).to eq({
                               updates: {
                                 "is_private" => [false, true]
                               },
                               rationale: rationale
                             })
    end
  end

  describe "#metadata" do
    context "with legacy audit" do
      subject(:audit_activity) { migrates the aud }

      it "populates the audit" do

      end
    end
  end
end
