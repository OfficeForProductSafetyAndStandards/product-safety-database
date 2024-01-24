class ChangeNotificationRiskLevel
  include Interactor
  include EntitiesToNotify

  AUDIT_ACTIVITY_CLASS = AuditActivity::Investigation::RiskLevelUpdated

  delegate :notification, :risk_level, :user, :change_action, :updated_risk_level, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.risk_level = nil unless Investigation.risk_levels.key?(context.risk_level)

    notification.assign_attributes(risk_level: risk_level.presence)

    context.change_action = Investigation::RiskLevelChange.new(notification).change_action
    return unless change_action

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_risk_level_update
    end

    context.updated_risk_level = notification.decorate.risk_level_description
    send_email(notification, user) unless context.silent
  end

private

  def create_audit_activity_for_risk_level_update
    AUDIT_ACTIVITY_CLASS.create!(
      added_by_user: user,
      investigation: notification,
      metadata: AUDIT_ACTIVITY_CLASS.build_metadata(notification, change_action)
    )
  end

  def send_email(notification, user)
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.notification_risk_level_updated(
        email:,
        name: entity.name,
        notification:,
        update_verb: change_action.to_s,
        level: updated_risk_level
      ).deliver_later
    end
  end
end
