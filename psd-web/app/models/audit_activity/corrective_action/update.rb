class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action_id: corrective_action.id, updates: corrective_action.previous_changes }
  end
end
