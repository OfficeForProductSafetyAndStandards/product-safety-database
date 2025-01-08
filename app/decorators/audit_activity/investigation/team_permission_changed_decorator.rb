class AuditActivity::Investigation::TeamPermissionChangedDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, team_name: metadata["team"]["name"])
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: added_by_user&.decorate&.display_name(viewer:), date: created_at.to_formatted_s(:govuk))
  end

  def new_permission
    I18n.t(".permission.#{metadata['permission']['new']}", scope: object.class.i18n_scope)
  end

  def old_permission
    I18n.t(".permission.#{metadata['permission']['old']}", scope: object.class.i18n_scope)
  end
end
