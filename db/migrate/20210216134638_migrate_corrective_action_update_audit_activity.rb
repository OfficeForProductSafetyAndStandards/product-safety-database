class MigrateCorrectiveActionUpdateAuditActivity < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { migrate_corrective_action_update_audit_activities }
      end
    end
  end

private

  def migrate_corrective_action_update_audit_activities
    CorrectiveAction.find_each do |corrective_action|
      AuditActivity::CorrectiveAction::Update.where("metadata->>'corrective_action_id' = ?", corrective_action.id.to_s).order(created_at: :desc).find_each do |audit_activity|
        AuditActivity::CorrectiveAction::Update.migrate_geographic_scope!(audit_activity)
      end
    end
  end
end
