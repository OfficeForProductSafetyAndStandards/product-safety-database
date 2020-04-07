class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "Status updated: coronavirus related"
    body = investigation.coronavirus_related? ? "The case is related to the coronavirus outbreak." : "The case is not related to the coronavirus outbreak."
    super(investigation, title, body)
  end

  def email_update_text
    "#{investigation.case_type.titleize} coronavirus relared status was updated by #{source&.show&.titleize}."
  end
end
