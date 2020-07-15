class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, previous_attachment)
    updated_values = corrective_action.previous_changes

    current_attachment = corrective_action.documents.first

    if previous_attachment.filename != current_attachment.filename
      updated_values["filename"] = [previous_attachment.filename, corrective_action.documents.first.filename]
    end

    if previous_attachment.metadata[:description] != current_attachment.metadata[:description]
      updated_values["file_description"] = [previous_attachment.metadata[:description], current_attachment.metadata[:description]]
    end

    { corrective_action_id: corrective_action.id, updates: updated_values }
  end
end
