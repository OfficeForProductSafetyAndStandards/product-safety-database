class DeleteDocument
  include Interactor
  include EntitiesToNotify

  delegate :document, :parent, :user, to: :context

  def call
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Document should be an instance of ActiveStorage::Attachment") unless document.is_a?(ActiveStorage::Attachment)

    ActiveRecord::Base.transaction do
      create_audit_activity if investigation
      document.destroy!
    end

    send_notification_email if investigation
  end

private

  def audit_activity_metadata
    AuditActivity::Document::Destroy.build_metadata(document)
  end

  def create_audit_activity
    activity = AuditActivity::Document::Destroy.create!(
      metadata: audit_activity_metadata,
      added_by_user: user,
      investigation:
    )

    activity.attachment.attach(document.blob)
  end

  def investigation
    parent if parent.is_a?(Investigation)
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(viewer = nil)
    "Document attached to the notification was removed by #{user&.decorate&.display_name(viewer:)}."
  end

  def email_subject
    "Notification updated"
  end
end
