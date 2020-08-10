class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, previous_attachment)
    updated_values = corrective_action
                       .previous_changes.except(:date_decided_day, :date_decided_month, :date_decided_year, :related_file)

    current_attachment = corrective_action.documents.first

    if previous_attachment && current_attachment
      if previous_attachment.filename != current_attachment.filename
        updated_values["filename"] = [previous_attachment.filename.to_s, current_attachment.filename.to_s]
      end
      if previous_attachment.metadata[:description] != current_attachment.metadata[:description]
        updated_values["file_description"] = [previous_attachment.metadata[:description], current_attachment.metadata[:description]]
      end
    else
      if previous_attachment&.filename != current_attachment&.filename
        updated_values["filename"] = [previous_attachment&.filename, current_attachment&.filename]
      end
      if previous_attachment&.metadata&.dig(:description) != current_attachment&.metadata&.dig(:description)
        updated_values["file_description"] = [previous_attachment&.metadata&.dig(:description), current_attachment&.metadata&.dig(:description)]
      end
    end

    { corrective_action_id: corrective_action.id, updates: updated_values }
  end

  def title(_user = nil)
    "Corrective action"
  end

  def subtitle_slug
    "Edited"
  end
end
