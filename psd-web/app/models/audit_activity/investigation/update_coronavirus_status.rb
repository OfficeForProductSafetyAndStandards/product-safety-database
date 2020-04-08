class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  def self.from(investigation)
    super(investigation, I18n.t(".title"), I18n.t(".body.#{investigation.coronavirus_related}"))
  end

  def email_update_text
    "#{investigation.case_type.titleize} coronavirus relared status was updated by #{source&.show&.titleize}."
  end
end
