class AuditActivity::AccidentOrIncident::AccidentOrIncidentAdded < AuditActivity::Base
  def self.from(*)
    raise "Deprecated - use AddAccidentOrIncidentToCase.call instead"
  end

  def self.build_metadata(accident_or_incident)
    {
      accident_or_incident_id: accident_or_incident.id,
      date: accident_or_incident.date,
      is_date_known: accident_or_incident.is_date_known,
      product_id: accident_or_incident.product_id,
      severity: accident_or_incident.severity,
      severity_other: accident_or_incident.severity_other,
      usage: accident_or_incident.usage,
      additional_info: accident_or_incident.additional_info,
      event_type: accident_or_incident.event_type
    }
  end

  def title(*)
    "Accident or Incident"
  end

  def subtitle_slug
    "Added"
  end

  def product_assessed
    Product.find(metadata["product_id"])
  end

  def further_details
    metadata["additional_info"].presence
  end

  def date(accident_or_incident)
    accident_or_incident.is_date_known ? date : 'Unknown'
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
