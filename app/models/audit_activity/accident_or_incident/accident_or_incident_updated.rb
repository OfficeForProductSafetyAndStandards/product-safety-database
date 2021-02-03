class AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated < AuditActivity::Base
  def self.from(*)
    raise "Deprecated - use UpdateAccidentOrIncident.call instead"
  end

  def self.build_metadata(accident_or_incident)
    updates = accident_or_incident.previous_changes.slice(
      :date,
      :product_id,
      :severity,
      :severity_other,
      :usage,
      :additional_info,
    )

    {
      accident_or_incident_id: accident_or_incident.id,
      updates: updates,
      event_type: accident_or_incident.event_type
    }
  end

  def date_changed?
     new_date
  end

  def new_date
    updates["date"]&.second
  end

  def product_changed?
    new_product_id
  end

  def new_product_id
    updates["product_id"]&.second
  end

  def severity_changed?
    new_severity
  end

  def new_severity
    updates["severity"]&.second
  end

  def usage_changed?
    new_usage
  end

  def new_usage
    updates["usage"]&.second
  end

  # def risk_level_changed?
  #   new_risk_level || new_custom_risk_level
  # end
  #
  # def assessed_by_changed?
  #   new_assessed_by_team_id || new_assessed_by_business_id || new_assessed_by_other
  # end
  #
  # def products_changed?
  #   new_product_ids
  # end
  #
  # def new_assessed_on
  #   date = updates["assessed_on"]&.second
  #   return nil unless date
  #
  #   Date.parse(date)
  # end
  #
  # def new_risk_level
  #   updates["risk_level"]&.second
  # end
  #
  # def new_filename
  #   updates["filename"]&.second
  # end
  #
  # def new_assessed_by_team
  #   if new_assessed_by_team_id
  #     Team.find(new_assessed_by_team_id)
  #   end
  # end
  #
  # def new_assessed_by_business
  #   if new_assessed_by_business_id
  #     Business.find(new_assessed_by_business_id)
  #   end
  # end
  #
  # def new_assessed_by_team_id
  #   updates["assessed_by_team_id"]&.second
  # end
  #
  # def new_assessed_by_business_id
  #   updates["assessed_by_business_id"]&.second
  # end
  #
  # def new_assessed_by_other
  #   updates["assessed_by_other"]&.second
  # end
  #
  # def new_custom_risk_level
  #   updates["custom_risk_level"]&.second
  # end
  #
  # def new_product_ids
  #   updates["product_ids"]&.second
  # end
  #
  # def new_products
  #   Product.find(new_product_ids)
  # end
  #
  # def new_details
  #   updates["details"]&.second
  # end
  #
  # def risk_assessment_id
  #   metadata["risk_assessment_id"]
  # end
  #
  # def title(_)
  #   "Risk assessment edited"
  # end
  #
  # def subtitle_slug
  #   "Edited"
  # end
  #
  # def products_assessed
  #   Product.find(metadata["product_ids"])
  # end
  #
  # def further_details
  #   metadata["details"].presence
  # end

private

  def updates
    metadata["updates"]
  end

  # Do not send investigation_updated mail when risk assessment updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
