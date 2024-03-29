class AddEmailToNotification
  include Interactor
  include EntitiesToNotify

  delegate :notification, :user, :email, :correspondence_date, :correspondent_name, :email_address, :email_direction, :overview, :details, :email_subject, :email_file, :email_attachment, :attachment_description, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.email = notification.emails.create!(
      correspondent_name:,
      correspondence_date:,
      email_address:,
      email_direction:,
      overview:,
      details:,
      email_subject:,
      email_file:,
      email_attachment:
    )

    if email.email_attachment.attached? && attachment_description.present?
      update_attachment_description!
    end

    create_audit_activity(email, notification)

    send_notification_email(notification, user)
  end

private

  def audit_activity_metadata
    AuditActivity::Correspondence::AddEmail.build_metadata(email)
  end

  def create_audit_activity(correspondence, notification)
    activity = AuditActivity::Correspondence::AddEmail.create!(
      metadata: audit_activity_metadata,
      added_by_user: user,
      investigation: notification,
      title: nil,
      correspondence:
    )

    activity.attach_blob(correspondence.email_file.blob, :email_file) if correspondence.email_file.attached?
    activity.attach_blob(correspondence.email_attachment.blob, :email_attachment) if correspondence.email_attachment.attached?
  end

  def update_attachment_description!
    context.email.email_attachment.blob.metadata[:description] = attachment_description
    context.email.email_attachment.blob.save!
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

  def email_update_text(viewer = nil)
    "Email details added to the notification by #{user&.decorate&.display_name(viewer:)}."
  end
end
