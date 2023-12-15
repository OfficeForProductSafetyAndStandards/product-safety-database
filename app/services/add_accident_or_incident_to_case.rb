class AddAccidentOrIncidentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :date, :is_date_known, :investigation_product_id, :severity, :severity_other, :usage, :additional_info, :user, :type, :accident_or_incident, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    params = { date:, is_date_known:, investigation_product_id:, severity:, severity_other:, usage:, additional_info:, type: }

    ActiveRecord::Base.transaction do
      context.accident_or_incident = investigation.unexpected_events.create!(params)

      create_audit_activity
    end
    send_notification_email
  end

private

  def create_audit_activity
    AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.create!(
      added_by_user: user,
      investigation:,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil,
      investigation_product:
    )
  end

  def audit_activity_metadata
    AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded.build_metadata(accident_or_incident)
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{type} was added to the notification by #{user.decorate.display_name(viewer: recipient)}.",
        "Notification updated"
      ).deliver_later
    end
  end

  def investigation_product
    InvestigationProduct.find(investigation_product_id)
  end
end
