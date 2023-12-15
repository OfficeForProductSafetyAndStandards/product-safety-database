class AuditActivity::Investigation::UpdateStatusDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, case_type: "Notification", status: new_status)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: added_by_user&.decorate&.display_name(viewer:), date: created_at.to_formatted_s(:govuk))
  end

  def new_status
    new_is_closed? ? "closed" : "re-opened"
  end

  def rationale
    metadata["rationale"]
  end

private

  def new_is_closed?
    metadata.dig("updates", "is_closed", 1)
  end
end
