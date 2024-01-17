class AddPhoneCallToNotification
  include Interactor
  include EntitiesToNotify

  delegate :activity, :notification, :correspondence, :user, :transcript, :correspondence_date, :correspondent_name, :overview, :details, :phone_number, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    Correspondence.transaction do
      context.correspondence = notification.phone_calls.create!(
        transcript:,
        correspondence_date:,
        phone_number:,
        correspondent_name:,
        overview:,
        details:
      )

      context.activity = AuditActivity::Correspondence::AddPhoneCall.create!(
        added_by_user: user,
        investigation: notification,
        correspondence:,
        metadata: AuditActivity::Correspondence::AddPhoneCall.build_metadata(correspondence)
      )

      send_notification_email(notification, user)
    end
  end

private

  def send_notification_email(notification, user)
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |entity|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        entity.name,
        entity.email,
        email_update_text(entity),
        email_subject
      ).deliver_later
    end
  end

  def email_subject
    I18n.t("add_phone_call_to_case.email_subject_text", case_type: email_case_type)
  end

  def email_case_type
    "Notification"
  end

  def email_update_text(recipient)
    "Phone call details added to the notification by #{user.decorate.display_name(viewer: recipient)}."
  end
end
