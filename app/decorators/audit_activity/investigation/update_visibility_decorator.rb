class AuditActivity::Investigation::UpdateVisibilityDecorator < ApplicationDecorator
  delegate_all

  def title(_viewer)
    I18n.t(".title", scope: object.class.i18n_scope, case_type: "notification", visibility: new_visibility)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: object.class.i18n_scope, user_name: added_by_user&.decorate&.display_name(viewer:), date: created_at.to_formatted_s(:govuk))
  end

  def new_visibility
    new_is_private? ? "restricted" : "unrestricted"
  end

  def rationale
    metadata["rationale"]
  end

  def user_name
    added_by_user.name
  end

  def govuk_created_at
    created_at.to_formatted_s(:govuk)
  end

private

  def new_is_private?
    metadata.dig("updates", "is_private", 1)
  end
end
