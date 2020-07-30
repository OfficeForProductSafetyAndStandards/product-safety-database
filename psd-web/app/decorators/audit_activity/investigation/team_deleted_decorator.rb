class AuditActivity::Investigation::TeamDeletedDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, team_name: metadata["team"]["name"], case_type: investigation.case_type.downcase)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: source&.show(viewer), date: created_at.to_s(:govuk))
  end
end
