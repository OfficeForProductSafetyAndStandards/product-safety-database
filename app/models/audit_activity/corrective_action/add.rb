class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action, changes)
    { corrective_action_id: corrective_action.id, updates: changes }
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  def title(_viewing_user = nil)
    action_name = metadata.dig("updates", "action", 1)

    truncated_action = CorrectiveAction::TRUNCATED_ACTION_MAP[action_name.to_sym]
    return "#{truncated_action}: #{product.name}" unless action_name.inquiry.other?

    metadata.dig("updates", "other_action", 1)
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
