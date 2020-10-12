class AddPhoneCallToCase
  include Interactor

  delegate :investigation, :correspondence, :user, :transcript, :correspondence_date, :correspondent_name, :overview, :details, :phone_number, to: :context

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

      AuditActivity::Correspondence::AddPhoneCall.create!(
        source: UserSource.new(user: user),
        investigation: investigation,
        correspondence: correspondence,
        metadata: AuditActivity::Correspondence::AddPhoneCall.build_metadata
      )
    end
  end
end
