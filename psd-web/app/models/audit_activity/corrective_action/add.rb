class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.from(corrective_action)
    super(corrective_action)
  end

  def email_update_text(viewing_user = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
