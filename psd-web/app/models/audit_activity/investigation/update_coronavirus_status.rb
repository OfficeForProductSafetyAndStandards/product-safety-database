class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  private_class_method def self.i18n_scope
    model_name.i18n_key.to_s.split("/")
  end

  def self.from(investigation)
    super(investigation, I18n.t(".title.#{investigation.coronavirus_related}", scope: i18n_scope), I18n.t(".body.#{investigation.coronavirus_related}", scope: i18n_scope))
  end

  def email_update_text
    I18n.t(".email_update_text", scope: i18n_scope, case_type: investigation.case_type.titleize, source: source&.show&.titleize)
  end
end
