class ChangeNotificationName
  include Interactor
  include EntitiesToNotify

  delegate :notification, :user_title, :user, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No case name supplied") unless user_title.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    notification.assign_attributes(user_title:)
    return if notification.changes.none?

    ActiveRecord::Base.transaction do
      notification.save!
      create_audit_activity_for_user_title_changed
    end

    send_notification_email unless context.silent
  end

private

  def create_audit_activity_for_user_title_changed
    metadata = activity_class.build_metadata(notification)
    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateCaseName
  end

  def send_notification_email
    email_recipients_for_case_owner(notification).each do |recipient|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Notification name updated"
      ).deliver_later
    end
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Notification name was updated by #{user_name}."
  end
end
