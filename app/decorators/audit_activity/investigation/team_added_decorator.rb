class AuditActivity::Investigation::TeamAddedDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, team_name: metadata["team"]["name"], case_type: investigation.case_type.downcase)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: source&.show(viewer), date: created_at.to_s(:govuk))
  end

  def permission
    I18n.t(".permission.#{metadata['permission']}", scope: object.class.i18n_scope)
  end
end
