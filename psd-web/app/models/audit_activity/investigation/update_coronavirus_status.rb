class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  def self.from(investigation)
    i18n_scope = model_name.i18n_key.to_s.split("/")
    super(investigation, I18n.t(".title.#{investigation.coronavirus_related}", scope: i18n_scope), I18n.t(".body.#{investigation.coronavirus_related}", scope: i18n_scope))
  end

  def email_update_text
    "#{investigation.case_type.titleize} coronavirus relared status was updated by #{source&.show&.titleize}."
  end
end
