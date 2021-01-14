class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.build_metadata(corrective_action)
    { corrective_action_id: corrective_action.id }
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  def title(_viewing_user)
    corrective_action.decorate.supporting_information_title
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
