class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, changes)
    {
      corrective_action_id: corrective_action.id,
      updates: changes.except("document")
    }
  end

  def self.migrate_geographic_scope!(audit_activity)
    return unless (geographic_scope_updates = audit_activity.metadata.dig("updates", "geographic_scope"))

    audit_activity.metadata["updates"]["geographic_scopes"] =
      geographic_scope_updates
        .map { |geographic_scope| CorrectiveAction::GEOGRAPHIC_SCOPES_MIGRATION_MAP[geographic_scope] }

    audit_activity.save!
  end

  def title(_user = nil)
    "Corrective action"
  end

  def subtitle_slug
    "Edited"
  end

  def corrective_action
    @corrective_action ||= begin
                             if (corrective_action_id = metadata&.dig("corrective_action_id"))
                               CorrectiveAction.find_by!(id: corrective_action_id)
                             else
                               super
                             end
                           end
  end
end
