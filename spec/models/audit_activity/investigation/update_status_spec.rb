require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateStatus, :with_stubbed_elasticsearch, :with_stubbed_mailer do
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
        rationale: rationale
      })
    end
  end

  describe "#migrate_to_metadata" do
    subject(:audit_activity) { create(:legacy_audit_investigation_update_status) }

    context "when the case was closed" do
      it "populates the metadata" do
        expect { audit_activity.migrate_to_metadata }
          .to change(audit_activity, :metadata)
                .from(nil)
                .to("updates" => { "is_closed" => [false, true], "date_closed" => [nil, JSON.parse(audit_activity.created_at.to_json)] })
      end
    end

    context "when the case was re-opened" do
      before { audit_activity.update!(title: "Allegation reopened") }

      it "populates the metadata" do
        expect { audit_activity.migrate_to_metadata }
          .to change(audit_activity, :metadata)
                .from(nil)
                .to("updates" => { "is_closed" => [true, false] })
      end
    end
  end
end
