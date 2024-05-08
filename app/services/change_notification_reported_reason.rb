class ChangeNotificationReportedReason
  include Interactor
  include EntitiesToNotify

  delegate :notification, :hazard_type, :hazard_description, :non_compliant_reason, :reported_reason, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_attributes

    if notification.reported_reason == "safe_and_compliant"
      ActiveRecord::Base.transaction do
        notification.save!
        create_audit_activity_for_safety_and_compliance_change
      end

      context.changes_made = true

      send_notification_email(notification, user) unless context.silent
    end
  end

private

  def assign_attributes
    if reported_reason == "safe_and_compliant"
      context.hazard_description = nil
      context.hazard_type = nil
      context.non_compliant_reason = nil
      notification.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: nil, reported_reason:)
    end
  end

  def create_audit_activity_for_safety_and_compliance_change
    metadata = activity_class.build_metadata(notification)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeSafetyAndComplianceData
  end

  def send_notification_email(notification, user)
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        entity.name,
        entity.email,
        "#{user.name} (#{user.team.name}) edited safety and compliance data on the notification.",
        "Safety and compliance data edited for notification"
      ).deliver_later
    end
  end
end
