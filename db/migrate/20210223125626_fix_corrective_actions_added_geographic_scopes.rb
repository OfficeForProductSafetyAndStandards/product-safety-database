class FixCorrectiveActionsAddedGeographicScopes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          AuditActivity::CorrectiveAction::Add.where("jsonb_typeof(metadata->'corrective_action'->'geographic_scopes') != 'array'").find_each do |audit_activity|
            geographic_scopes = CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[audit_activity.metadata.dig("corrective_action", "geographic_scopes")]
            audit_activity.metadata["corrective_action"]["geographic_scopes"] = geographic_scopes
            audit_activity.save!
          end
        end
      end
    end
  end
end
