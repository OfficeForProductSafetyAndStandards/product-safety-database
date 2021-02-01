class AddAccidentOrIncidentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :date, :is_date_known, :product, :severity, :severity_other, :usage, :additional_info, :user, :event_type, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      context.accident_or_incident = investigation.accident_or_incidents.create!(
        date: date,
        is_date_known: is_date_known,
        product_id: product,
        severity: severity,
        severity_other: severity_other,
        usage: usage,
        additional_info: additional_info,
        event_type: event_type
      )

      # create_audit_activity
    end
    # send_notification_email
  end

private

  # def create_audit_activity
  #   AuditActivity::RiskAssessment::RiskAssessmentAdded.create!(
  #     source: UserSource.new(user: user),
  #     investigation: investigation,
  #     metadata: audit_activity_metadata,
  #     title: nil,
  #     body: nil
  #   )
  # end

  # def audit_activity_metadata
  #   AuditActivity::RiskAssessment::RiskAssessmentAdded.build_metadata(risk_assessment)
  # end

  # def send_notification_email
  #   email_recipients_for_case_owner.each do |recipient|
  #     NotifyMailer.investigation_updated(
  #       investigation.pretty_id,
  #       recipient.name,
  #       recipient.email,
  #       "Risk assessment was added to the #{investigation.case_type} by #{user.decorate.display_name(viewer: recipient)}.",
  #       "#{investigation.case_type.upcase_first} updated"
  #     ).deliver_later
  #   end
  # end
end
