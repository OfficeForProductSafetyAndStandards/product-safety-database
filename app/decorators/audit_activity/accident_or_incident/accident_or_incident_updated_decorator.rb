class AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdatedDecorator < ActivityDecorator
  def new_usage
    I18n.t(".accident_or_incident.usage.#{activity.new_usage}")
  end

  def type
    activity.metadata["type"].downcase
  end

  def additional_info
    metadata.dig("updates", "additional_info", 1).presence || "Removed"
  end

  def investigation_product_updated?
    metadata.dig("updates", "investigation_product_id", 1)
  end

  def date_changed?
    new_date_information?
  end

  def new_date
    return unless new_date_information?

    return "Unknown" if return_unknown_date?

    new_date = metadata.dig("updates", "date", 1)
    Date.parse(new_date).to_formatted_s(:govuk)
  end

  def severity_changed?
    new_severity_information?
  end

  def new_severity
    return unless new_severity_information?

    return metadata.dig("updates", "severity_other", 1) if use_severity_other?

    I18n.t(".accident_or_incident.severity.#{metadata.dig('updates', 'severity', 1)}")
  end

private

  def use_severity_other?
    severity_is_unchanged_or_other? && has_severity_other_changed?
  end

  def severity_is_unchanged_or_other?
    metadata.dig("updates", "severity", 1).nil? || metadata.dig("updates", "severity", 1) == "other"
  end

  def new_severity_information?
    has_severity_changed? || has_severity_other_changed?
  end

  def has_severity_changed?
    metadata.dig("updates", "severity", 1).present?
  end

  def has_severity_other_changed?
    metadata.dig("updates", "severity_other", 1).present?
  end

  def new_date_information?
    has_date_changed? || has_is_date_known_changed?
  end

  def has_date_changed?
    metadata.dig("updates", "date", 1).present?
  end

  def has_is_date_known_changed?
    !metadata.dig("updates", "is_date_known", 1).nil?
  end

  def return_unknown_date?
    has_is_date_known_changed? && updated_date_is_not_known?
  end

  def updated_date_is_not_known?
    updated_date_is_not_known = metadata.dig("updates", "is_date_known", 1)

    ActiveModel::Type::Boolean.new.cast(updated_date_is_not_known) == false
  end
end
