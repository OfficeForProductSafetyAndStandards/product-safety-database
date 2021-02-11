class UpdateAccidentOrIncident
  include Interactor
  include EntitiesToNotify

  delegate :accident_or_incident, :investigation, :date, :is_date_known, :product_id, :severity, :severity_other, :usage, :additional_info, :user, :type, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      accident_or_incident.assign_attributes(
        date: updated_date,
        is_date_known: is_date_known,
        product_id: product_id,
        severity: severity,
        severity_other: updated_custom_severity,
        usage: usage,
        additional_info: additional_info
      )

      break if no_changes?

      accident_or_incident.save!

      create_audit_activity
      send_notification_email
    end
  end

  def create_audit_activity
    AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated.create!(
      source: user_source,
      investigation: investigation,
      metadata: audit_activity_metadata,
      title: nil,
      body: nil
    )
  end

  def audit_activity_metadata
    AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated.build_metadata(accident_or_incident)
  end

  def user_source
    @user_source ||= UserSource.new(user: user)
  end

  def no_changes?
    !accident_or_incident.changed?
  end

  def updated_date
    is_date_known == "yes" ? date : nil
  end

  def updated_custom_severity
    severity == "other" ? severity_other : nil
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user_source.show(recipient)} edited an #{type} on the #{investigation.case_type}.",
        "#{type} edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
