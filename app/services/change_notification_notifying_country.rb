class ChangeNotificationNotifyingCountry
  include Interactor
  include EntitiesToNotify

  delegate :notification, :notifying_country_uk, :notifying_country_overseas, :overseas_or_uk, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No selection made") if overseas_or_uk.blank?
    context.fail!(error: "No country selected") if overseas_or_uk == "uk" && notifying_country_uk.blank?
    context.fail!(error: "No country selected") if overseas_or_uk == "overseas" && notifying_country_overseas.blank?

    assign_country
    return if notification.changes.none?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_notifying_country_changed
    end

    send_notification_email(notification, user)
  end

private

  def create_audit_activity_for_notifying_country_changed
    metadata = activity_class.build_metadata(notification)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeNotifyingCountry
  end

  def assign_country
    notification.assign_attributes(notifying_country: notifying_country_uk) if overseas_or_uk == "uk"
    notification.assign_attributes(notifying_country: notifying_country_overseas) if overseas_or_uk == "overseas"
  end

  def send_notification_email(notification, user)
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.notification_updated(
        notification.pretty_id,
        entity.name,
        email,
        "#{user.name} (#{user.team.name}) edited notifying country on the notification.",
        "Notifying country edited for notification"
      ).deliver_later
    end
  end
end
