class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action: corrective_action.attributes, document: corrective_action.document.attributes }
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  def title(_viewing_user = nil)
    action_name = metadata.dig("corrective_action", "action")

    truncated_action = CorrectiveAction::TRUNCATED_ACTION_MAP[action_name.to_sym]
    return "#{truncated_action}: #{product.name}" unless action_name.inquiry.other?

    metadata.dig("corrective_action", "other_action")
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
