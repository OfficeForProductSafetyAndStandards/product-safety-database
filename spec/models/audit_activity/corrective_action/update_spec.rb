require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Update, :with_stubbed_opensearch, :with_stubbed_mailer do
  describe ".migrate_geographic_scope" do
    let(:audit_activity)       { create(:legacy_audit_update_activity_corrective_action, metadata:) }
    let(:old_geographic_scope) { "Regional" }
    let(:new_geographic_scope) { "Local" }
    let(:metadata) do
      {
        updates: {
          geographic_scope: [old_geographic_scope, new_geographic_scope]
        }
      }
    end

    it "migrates geographic scope" do
      expect { described_class.migrate_geographic_scope!(audit_activity) }
        .to change { audit_activity.reload.metadata["updates"]["geographic_scopes"] }
        .from(nil)
        .to([CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[old_geographic_scope], CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[new_geographic_scope]])
    end
  end

  describe "#metadata" do
    # TODO: remove once migrated
    context "when metadata contains a Product reference" do
      let(:investigation) { create(:allegation, :with_products) }
      let(:investigation_product) { investigation.investigation_products.first }
      let(:new_investigation_product) { create(:investigation_product, investigation:) }
      let(:activity) { described_class.new(investigation:, metadata: { updates: { product_id: [investigation_product.product_id, new_investigation_product.product_id] } }.deep_stringify_keys) }

      it "translates the Product ID to InvestigationProduct ID" do
        expect(activity.metadata["updates"]["product_id"]).to be_nil
        expect(activity.metadata["updates"]["investigation_product_id"]).to eq([investigation_product.id, new_investigation_product.id])
      end
    end
  end
end
