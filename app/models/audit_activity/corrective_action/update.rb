class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, changes)
    {
      corrective_action_id: corrective_action.id,
      updates: changes.except("document")
    }
  end

  def title(_user = nil)
    "Corrective action"
  end

  def subtitle_slug
    "Edited"
  end
end
