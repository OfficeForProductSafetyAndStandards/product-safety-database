require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateVisibility, :with_stubbed_mailer do
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
        rationale:
      })
    end
  end

  describe "#metadata" do
    context "with legacy audit" do
      subject(:audit_activity) { create(:legacy_audit_investigation_visibility_status, title:) }

      context "with restricted status" do
        let(:title) { "Allegation visibility\n            Restricted" }

        it "populates the audit" do
          expect(audit_activity.metadata).to eq("updates" => { "is_private" => [nil, true] })
        end
      end

      context "with unrestricted status" do
        let(:title) { "Allegation visibility\n            Unrestricted" }

        it "populates the audit" do
          expect(audit_activity.metadata).to eq("updates" => { "is_private" => [nil, false] })
        end
      end
    end
  end
end
