class AddPhoneCallToCase
  include Interactor

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
        metadata: AuditActivity::Correspondence::AddPhoneCall.build_metadata
      )

      send_notification_email
    end
  end

private

  def entities_to_notify
    entities = []
    investigation.teams_with_access.each do |team|
      if team.email.present?
        entities << team
      else
        users_from_team = team.users.active
        entities.concat(users_from_team)
      end
    end
    entities.uniq - [context.user]
  end

  def send_notification_email
    entities_to_notify.each do |entity|
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
