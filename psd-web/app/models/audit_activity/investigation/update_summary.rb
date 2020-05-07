class AuditActivity::Investigation::UpdateSummary < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "#{investigation.case_type.upcase_first} summary updated"
    super(investigation, title, investigation.description)
  end

  def email_update_text(viewing_user = nil)
    "#{investigation.case_type.upcase_first} summary was updated by #{source&.show(viewing_user)}."
  end
end
