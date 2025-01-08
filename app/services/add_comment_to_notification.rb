class AddCommentToNotification
  include Interactor
  include EntitiesToNotify

  delegate :notification, :body, :user, :comment, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      context.comment = AuditActivity::Investigation::AddComment.create!(
        added_by_user: user,
        metadata: audit_activity_metadata,
        investigation_id: notification.id
      )
    end

    send_notification_email(notification, user)
  end

  def audit_activity_metadata
    AuditActivity::Investigation::AddComment.build_metadata(body)
  end

  def send_notification_email(notification, _user)
    return unless notification.sends_notifications?

    email_recipients_for_case_owner(notification).each do |recipient|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(recipient)
    "#{user.decorate.display_name(viewer: recipient)} commented on the notification."
  end

  def email_subject
    "Notification updated"
  end
end
