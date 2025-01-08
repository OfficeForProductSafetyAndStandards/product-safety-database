class AuditActivity::Investigation::ChangeSafetyAndComplianceDataDecorator < ActivityDecorator
  def new_usage
    I18n.t(".accident_or_incident.usage.#{activity.new_usage}")
  end

  def new_reported_reason
    metadata.dig("updates", "reported_reason", 1)
  end

  def reported_reason_changed?
    new_reported_reason
  end

  def new_hazard_type
    metadata.dig("updates", "hazard_type", 1)
  end

  def hazard_type_changed?
    new_hazard_type
  end

  def new_hazard_description
    metadata.dig("updates", "hazard_description", 1)
  end

  def hazard_description_changed?
    new_hazard_description
  end

  def new_non_compliant_reason
    metadata.dig("updates", "non_compliant_reason", 1)
  end

  def non_compliant_reason_changed?
    new_non_compliant_reason
  end
end
