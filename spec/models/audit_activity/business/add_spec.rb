require "rails_helper"

RSpec.describe AuditActivity::Business::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:audit_activity) { create :legacy_audit_business_added_status }

  describe "#migrate_to_metadata" do
    it "populates the metadata removing markdown escaping" do
      expect { audit_activity.migrate_to_metadata }
        .to change(audit_activity, :metadata).from(nil).to(
          "business" => JSON.parse(audit_activity.business.attributes.to_json),
          "investigation_business" => { "relationship" => "fulfillment_house" }
        )
    end
  end
end
