class AuditActivity::AccidentOrIncident::AccidentOrIncidentAddedDecorator < ActivityDecorator
  def date
    activity.metadata["date"] ? Date.parse(activity.metadata["date"]).to_formatted_s(:govuk) : "Unknown"
  end

  def severity
    activity.metadata["severity_other"].presence || I18n.t(".accident_or_incident.severity.#{activity.metadata['severity']}")
  end

  def type
    activity.metadata["type"].downcase
  end

  def usage
    I18n.t(".accident_or_incident.usage.#{activity.metadata['usage']}")
  end

  def additional_info
    activity.metadata["additional_info"]
  end
end
