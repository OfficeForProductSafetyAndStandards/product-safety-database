class FixCorrectiveActionAuditActivity < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          AuditActivity::CorrectiveAction::Add.where("metadata->'corrective_action'->>'id' IS NULL").find_each do |audit_activity|
            if audit_activity.corrective_action.present?
              audit_activity.metadata["corrective_action"]["id"] = audit_activity.corrective_action.id
              audit_activity.save!
            elsif audit_activity.investigation.corrective_actions.one?
              audit_activity.metadata["corrective_action"]["id"] = audit_activity.investigation.corrective_action_ids.first
              audit_activity.save!
            end
          end
        end
      end
    end
  end
end
