class FixDuration < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          AuditActivity::CorrectiveAction::Add.where("metadata->'corrective_action'->>'duration' IN (?)", CorrectiveAction::DURATION_TYPES.map(&:titleize)).find_each do |audit_activity|
            audit_activity.metadata["corrective_action"]["duration"] = audit_activity.metadata["corrective_action"]["duration"].downcase
            audit_activity.save!
          end
        end
      end
    end
  end
end
