class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "#{investigation.case_type.titleize} coronavirus related status updated"
    super(investigation, title, I18n.t(investigation.coronavirus_related, scope: "case.coronavirus_related"))
  end

  def email_update_text
    "#{investigation.case_type.titleize} coronavirus relared status was updated by #{source&.show&.titleize}."
  end
end
