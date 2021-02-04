class MigrateAuditActivitiesCorrectiveActionAdd < ActiveRecord::Migration[6.1]
  def change
    AuditActivity::CorrectiveAction::Add.where(metadata: nil).find_each do |audit_activity|
      audit_activity
        .update!(metadata: AuditActivity::CorrectiveAction::Add.metadata_from_legacy_audit_activity(audit_activity))
    end
  end
end
