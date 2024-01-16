RSpec.describe AuditActivity::Business::Destroy, :with_stubbed_mailer do
  subject(:audit_activity) { create(:legacy_audit_business_remove_status) }

  describe "#metadata" do
    context "with legacy audit" do
      it "populates the metadata" do
        expect(audit_activity.metadata).to eq({ "business" => JSON.parse(audit_activity.business.attributes.to_json) })
      end
    end
  end
end
