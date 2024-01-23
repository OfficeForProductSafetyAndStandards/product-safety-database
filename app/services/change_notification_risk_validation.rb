class ChangeNotificationRiskValidation
  include Interactor
  include EntitiesToNotify

  delegate :notification, :risk_validated_at, :risk_validated_by, :is_risk_validated, :risk_validation_change_rationale, :user, :change_action, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_risk_validation_attributes
    return if notification.changes.none?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_risk_validation_changed
    end

    context.changes_made = true

    send_notification_email
  end

private

  def create_audit_activity_for_risk_validation_changed
    metadata = activity_class.build_metadata(notification, risk_validation_change_rationale)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateRiskLevelValidation
  end

  def assign_risk_validation_attributes
    if is_risk_validated
      notification.assign_attributes(risk_validated_at:, risk_validated_by:)
      context.change_action = I18n.t("change_risk_validation.validated")
    else
      notification.assign_attributes(risk_validated_at: nil, risk_validated_by: nil)
      context.change_action = I18n.t("change_risk_validation.validation_removed")
    end
  end

  def send_notification_email
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.risk_validation_updated(
        email:,
        updater: user,
        name: entity.name,
        investigation: notification,
        action: change_action.to_s,
      ).deliver_later
    end
  end
end
