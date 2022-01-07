require "rails_helper"

RSpec.describe AuditActivity::Product::Destroy, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:audit_activity) { create :legacy_audit_product_destroyed }

  describe "#metadata" do
    context "when not migrated to new structure" do
      it "builds the new structure" do
        expect(audit_activity.metadata).to eq(
          "product" => JSON.parse(audit_activity.product.attributes.to_json),
          "reason" => "Product removed from case"
        )
      end
    end
  end
end
