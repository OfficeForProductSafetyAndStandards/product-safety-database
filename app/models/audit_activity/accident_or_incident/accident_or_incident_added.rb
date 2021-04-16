class AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded < AuditActivity::Base
  belongs_to :product, class_name: "::Product"

  def self.from(*)
    raise "Deprecated - use AddAccidentOrIncidentToCase.call instead"
  end

  def self.build_metadata(accident_or_incident)
    {
      accident_or_incident_id: accident_or_incident.id,
      date: accident_or_incident.date,
      is_date_known: accident_or_incident.is_date_known,
      severity: accident_or_incident.severity,
      severity_other: accident_or_incident.severity_other,
      usage: accident_or_incident.usage,
      additional_info: accident_or_incident.additional_info,
      type: accident_or_incident.type
    }
  end

  def title(*)
    metadata["type"]
  end

  def subtitle_slug
    "Added"
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
