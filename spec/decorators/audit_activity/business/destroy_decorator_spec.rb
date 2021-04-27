require "rails_helper"

RSpec.describe AuditActivity::Business::DestroyDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:audit_activity) { create(:legacy_audit_business_remove_status) }

  describe "#migrate_to_metadata" do
    it "populates the metadata correctly" do
      expect { audit_activity.migrate_to_metadata }
        .to change(audit_activity, :metadata)
              .from(nil)
              .to("business" => { "trading_name" => "A business name" })
    end
  end
end
