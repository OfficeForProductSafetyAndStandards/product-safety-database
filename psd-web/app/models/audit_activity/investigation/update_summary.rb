class AuditActivity::Investigation::UpdateSummary < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "#{investigation.case_type.upcase_first} summary updated"
    super(investigation, title, investigation.description)
  end

  def email_update_text(viewer = nil)
    "#{investigation.case_type.upcase_first} summary was updated by #{source&.show(viewer)}."
  end
end
