class UpdateAccidentOrIncident
  include Interactor
  include EntitiesToNotify

  delegate :accident_or_incident, :investigation, :date, :is_date_known, :product_id, :severity, :severity_other, :usage, :additional_info, :user, :event_type, to: :context

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
        additional_info: additional_info,
        event_type: event_type
      )

      break if no_changes?

      accident_or_incident.save!

      create_audit_activity
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
end
