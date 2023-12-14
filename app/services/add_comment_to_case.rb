class AddCommentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :body, :user, :comment, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      context.comment = AuditActivity::Investigation::AddComment.create!(
        added_by_user: user,
        metadata: audit_activity_metadata,
        investigation_id: investigation.id
      )
    end

    send_notification_email(investigation, user)
  end

  def audit_activity_metadata
    AuditActivity::Investigation::AddComment.build_metadata(body)
  end

  def send_notification_email(investigation, _user)
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(recipient)
    "#{user.decorate.display_name(viewer: recipient)} commented on the case."
  end

  def email_subject
    "Case updated"
  end
end
