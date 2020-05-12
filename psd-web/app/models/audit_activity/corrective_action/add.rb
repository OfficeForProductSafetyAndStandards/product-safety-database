class AuditActivity::CorrectiveAction::Add < AuditActivity::CorrectiveAction::Base
  def self.from(corrective_action)
    super(corrective_action)
  end

  def email_update_text(viewer = nil)
    "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Corrective action recorded"
  end
end
