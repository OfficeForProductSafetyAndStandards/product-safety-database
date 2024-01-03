# TODO: This service is missing specs
class UpdateAccidentOrIncident
  include Interactor
  include EntitiesToNotify

  delegate :accident_or_incident, :investigation, :date, :is_date_known, :investigation_product_id, :severity, :severity_other, :usage, :additional_info, :user, :type, to: :context

  def call
    context.fail!(error: "No accident or incident supplied") unless accident_or_incident.is_a?(UnexpectedEvent)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      accident_or_incident.assign_attributes(
        date: updated_date,
        is_date_known:,
        investigation_product_id:,
        severity:,
        severity_other: updated_custom_severity,
        usage:,
        additional_info:
      )

      break if no_changes?

      accident_or_incident.save!

      create_audit_activity
      send_notification_email
    end
  end

  def create_audit_activity
    AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated.create!(
      added_by_user: user,
      investigation:,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil,
      investigation_product_id:
    )
  end

  def audit_activity_metadata
    AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated.build_metadata(accident_or_incident)
  end

  def no_changes?
    !accident_or_incident.changed?
  end

  def updated_date
    is_date_known ? date : nil
  end

  def updated_custom_severity
    severity.inquiry.other? ? severity_other : ""
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user.decorate.display_name(viewer: recipient)} edited an #{type} on the notification.",
        "#{type} edited for notification"
      ).deliver_later
    end
  end
end
