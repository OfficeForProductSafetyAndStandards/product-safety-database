class AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated < AuditActivity::Base
  def self.build_metadata(accident_or_incident)
    updates = accident_or_incident.previous_changes.slice(
      :date,
      :is_date_known,
      :severity,
      :severity_other,
      :usage,
      :additional_info,
      :investigation_product_id
    )

    {
      accident_or_incident_id: accident_or_incident.id,
      updates:,
      type: accident_or_incident.type
    }
  end

  def title(*)
    metadata["type"]
  end

  def subtitle_slug
    "Updated"
  end

  def usage_changed?
    new_usage
  end

  def new_usage
    updates["usage"]&.second
  end

  def additional_info_changed?
    new_additional_info
  end

  def new_additional_info
    updates["additional_info"]&.second
  end

private

  def updates
    metadata["updates"]
  end

  def is_date_know_has_been_changed_from_no_to_yes?
    updates["is_date_known"]&.second
  end
end
