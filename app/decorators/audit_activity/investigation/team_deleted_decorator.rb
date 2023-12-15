class AuditActivity::Investigation::TeamDeletedDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, team_name: metadata["team"]["name"], case_type: "case")
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: added_by_user&.decorate&.display_name(viewer:), date: created_at.to_formatted_s(:govuk))
  end
end
