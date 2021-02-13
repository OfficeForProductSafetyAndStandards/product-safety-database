class AddAccidentOrIncidentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :date, :is_date_known, :product_id, :severity, :severity_other, :usage, :additional_info, :user, :type, :accident_or_incident, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    params = { date: date, is_date_known: is_date_known, product_id: product_id, severity: severity, severity_other: severity_other, usage: usage, additional_info: additional_info, type: type }

    ActiveRecord::Base.transaction do
      context.accident_or_incident = investigation.unexpected_events.create!(params)

      create_audit_activity
    end
    send_notification_email
  end

private

  def create_audit_activity
    AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil,
      product_id: product_id
    )
  end

  def audit_activity_metadata
    AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.build_metadata(accident_or_incident)
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{type} was added to the #{investigation.case_type} by #{user.decorate.display_name(viewer: recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
