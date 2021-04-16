require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Update, :with_stubbed_elasticsearch, :with_stubbed_mailer  do
  let(:audit_activity)       { create(:legacy_audit_update_activity_corrective_action, metadata: metadata) }
  let(:old_geographic_scope) { "Regional" }
  let(:new_geographic_scope) { "Local" }
  let(:metadata) do
    {
      updates: {
        geographic_scope: [old_geographic_scope, new_geographic_scope]
      }
    }
  end

  describe ".migrate_geographic_scope" do
    it "migrates geographic scope" do
      expect { described_class.migrate_geographic_scope!(audit_activity) }
        .to change { audit_activity.reload.metadata["updates"]["geographic_scopes"] }
        .from(nil)
        .to([CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[old_geographic_scope], CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[new_geographic_scope]])
    end
  end
end
