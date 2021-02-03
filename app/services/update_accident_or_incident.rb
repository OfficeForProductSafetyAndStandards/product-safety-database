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
    end
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
