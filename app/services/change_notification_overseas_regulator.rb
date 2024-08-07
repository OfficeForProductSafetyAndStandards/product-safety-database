class ChangeNotificationOverseasRegulator
  include Interactor
  include EntitiesToNotify

  delegate :notification, :is_from_overseas_regulator, :notifying_country, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    assign_overseas_regulator
    return if notification.changes[:notifying_country].blank?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_overseas_regulator_changed
    end

    send_notification_email(notification, user) unless context.silent
  end

private

  def create_audit_activity_for_overseas_regulator_changed
    metadata = activity_class.build_metadata(notification)
    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeOverseasRegulator
  end

  def assign_overseas_regulator
    country = is_from_overseas_regulator ? notifying_country : nil
    notification.assign_attributes(is_from_overseas_regulator:, notifying_country: country)
  end

  def send_notification_email(notification, user)
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.notification_updated(
        notification.pretty_id,
        entity.name,
        email,
        "#{user.name} (#{user.team.name}) edited overseas regulator on the notification.",
        "Overseas regulator edited for notification"
      ).deliver_later
    end
  end
end
