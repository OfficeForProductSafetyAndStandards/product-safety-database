class AuditActivity::CorrectiveAction::Update < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, previous_attachment)
    updated_values = corrective_action.previous_changes.except(:date_decided_day, :date_decided_month, :date_decided_year, :related_file)

    old_file_description = previous_attachment&.blob&.previous_changes&.dig(:metadata, 0, :description)
    old_filename = previous_attachment&.blob&.filename

    current_attachment = corrective_action.documents.first

    if old_filename != current_attachment&.filename
      updated_values["filename"] = if current_attachment
                                     [old_filename, corrective_action.documents.first.filename.to_s]
                                   else
                                     [old_filename, nil]
                                   end
    end

    if old_file_description && old_file_description != current_attachment&.metadata&.dig(:description)
      updated_values["file_description"] = [old_file_description, current_attachment.metadata[:description]]
    end

    { corrective_action_id: corrective_action.id, updates: updated_values }
  end

  def title(_user)
    "Corrective action"
  end

  def subtitle_slug
    "Edited"
  end
end
