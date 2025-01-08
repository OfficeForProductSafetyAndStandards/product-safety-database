class FixCorrectiveActionWithNoDateDecided < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { migrate_legacy_audit_record }
      end
    end
  end

private

  def migrate_legacy_audit_record
    unmigrated_audits = []
    AuditActivity::CorrectiveAction::Add.where("metadata->'corrective_action'->'date_decided' IS NULL").find_each do |audit_activity|
      audit_activity.update!(metadata: AuditActivity::CorrectiveAction::Add.metadata_from_legacy_audit_activity(audit_activity))
    rescue StandardError => e
      Rails.logger.error(e)
      unmigrated_audits << audit_activity.id
    end

    Rails.logger.info("Audit not migrated:")
    Rails.logger.info(unmigrated_audits.join(", "))
  end
end
