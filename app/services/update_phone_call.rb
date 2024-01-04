class UpdatePhoneCall
  include Interactor
  include EntitiesToNotify

  delegate :activity, :correspondence, :user, :transcript, :correspondence_date, :correspondent_name, :overview, :details, :phone_number, to: :context

  def call
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No phone call supplied") unless correspondence.is_a?(Correspondence::PhoneCall)

    correspondence.assign_attributes(
      correspondence_date:,
      phone_number:,
      correspondent_name:,
      overview:,
      details:
    )

    return unless any_changes?

    Correspondence.transaction do
      if transcript && correspondence.transcript_blob != transcript
        correspondence.transcript.attach(transcript)
      end

      correspondence.save!
      create_audit_activity
      send_notification_email(investigation, user)
    end
  end

private

  def investigation
    correspondence.investigation
  end

  def send_notification_email(investigation, user)
    return unless investigation.sends_notifications?

    email_recipients_for_team_with_access(investigation, user).each do |entity|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        entity.name,
        entity.email,
        email_update_text(entity),
        email_subject
      ).deliver_later
    end
  end

  def create_audit_activity
    context.activity = AuditActivity::Correspondence::PhoneCallUpdated.create!(
      added_by_user: user,
      investigation: correspondence.investigation,
      correspondence:,
      metadata: AuditActivity::Correspondence::PhoneCallUpdated.build_metadata(correspondence)
    )
  end

  def email_subject
    I18n.t("update_phone_call.email_subject_text", case_type: email_case_type)
  end

  def email_case_type
    "Notification"
  end

  def email_update_text(recipient)
    "Phone call details updated on the notification by #{user.decorate.display_name(viewer: recipient)}."
  end

  def any_changes?
    correspondence.has_changes_to_save? || (correspondence.transcript_blob != transcript)
  end
end
