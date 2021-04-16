class AddPhoneCallToCase
  include Interactor
  include EntitiesToNotify

  delegate :activity, :investigation, :correspondence, :user, :transcript, :correspondence_date, :correspondent_name, :overview, :details, :phone_number, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    Correspondence.transaction do
      context.correspondence = investigation.phone_calls.create!(
        transcript: transcript,
        correspondence_date: correspondence_date,
        phone_number: phone_number,
        correspondent_name: correspondent_name,
        overview: overview,
        details: details
      )

      context.activity = AuditActivity::Correspondence::AddPhoneCall.create!(
        source: UserSource.new(user: user),
        investigation: investigation,
        correspondence: correspondence,
        metadata: AuditActivity::Correspondence::AddPhoneCall.build_metadata(correspondence)
      )

      send_notification_email(investigation, user)
    end
  end

private

  def send_notification_email(investigation, user)
    email_recipients_for_team_with_access(investigation, user).each do |entity|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        entity.email,
        email_update_text,
        activity.email_subject_text
      ).deliver_later
    end
  end

  def email_update_text
    "Phone call details added to the #{investigation.case_type.upcase_first} by #{activity.source.show}."
  end
end
