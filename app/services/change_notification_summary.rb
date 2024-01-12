class ChangeNotificationSummary
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :summary, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No summary supplied") unless summary.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.assign_attributes(description: summary)
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_case_summary_changed
    end

    send_notification_email unless context.silent
  end

private

  def create_audit_activity_for_case_summary_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateSummary
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Notification summary updated"
      ).deliver_later
    end
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    "Notification summary was updated by #{user_name}."
  end
end
