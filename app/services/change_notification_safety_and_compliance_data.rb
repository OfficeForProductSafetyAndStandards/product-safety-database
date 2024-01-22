class ChangeNotificationSafetyAndComplianceData
  include Interactor
  include EntitiesToNotify

  delegate :notification, :hazard_type, :hazard_description, :non_compliant_reason, :reported_reason, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_attributes
    return if notification.changes.none?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_safety_and_compliance_change
    end

    context.changes_made = true

    send_notification_email(notification, user) unless context.silent
  end

private

  def assign_attributes
    if reported_reason.to_s == "safe_and_compliant"
      notification.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: nil, reported_reason:)
    end

    if reported_reason.to_s == "unsafe_and_non_compliant"
      notification.assign_attributes(hazard_description:, hazard_type:, non_compliant_reason:, reported_reason:)
    end

    if reported_reason.to_s == "unsafe"
      notification.assign_attributes(hazard_description:, hazard_type:, non_compliant_reason: nil, reported_reason:)
    end

    if reported_reason.to_s == "non_compliant"
      notification.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason:, reported_reason:)
    end

    # Clear everything so the user can re-choose if they chose "unsafe and/or non-compliant" and the previous choice was "safe and compliant"
    # to avoid clobbering previously-entered data
    if reported_reason.to_s == "unsafe_or_non_compliant" && notification.reported_reason == "safe_and_compliant"
      notification.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: nil, reported_reason: nil)
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
