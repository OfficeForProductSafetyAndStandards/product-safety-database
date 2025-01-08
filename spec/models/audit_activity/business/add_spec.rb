require "rails_helper"

RSpec.describe AuditActivity::Business::Add, :with_stubbed_mailer do
  subject(:audit_activity) { create :legacy_audit_business_added_status }

  describe "#metadata" do
    context "when not migrated to new struture" do
      it "builds the new structure" do
        expect(audit_activity.metadata).to eq(
          "business" => JSON.parse(audit_activity.business.attributes.to_json),
          "investigation_business" => { "relationship" => "fulfillment_house" }
        )
      end
    end
  end
end
