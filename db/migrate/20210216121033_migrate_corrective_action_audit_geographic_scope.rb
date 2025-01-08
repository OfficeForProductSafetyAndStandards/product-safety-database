class MigrateCorrectiveActionAuditGeographicScope < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { migrate_corrective_action_added_audit_activity }
      end
    end
  end

private

  def migrate_corrective_action_added_audit_activity
    AuditActivity::CorrectiveAction::Add.find_each { |audit_activity| AuditActivity::CorrectiveAction::Add.migrate_geographic_scopes!(audit_activity) }
  end
end
