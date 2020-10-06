class AddPhoneCallToCase
  include Interactor

  delegate :investigation, :correspondence, :user, :transcript, :correspondence_date, :correspondent_name, :overview, :details, :phone_number, to: :context

  def call
    context.correspondence = investigation.phone_calls.create!(
      transcript: transcript,
      correspondence_date: correspondence_date,
      phone_number: phone_number,
      correspondent_name: correspondent_name,
      overview: overview,
      details: details
    )

    AuditActivity::Correspondence::AddPhoneCall.from(correspondence, investigation)
  end
end
