class AuditActivity::CorrectiveAction::UpdateDecorator < ::ActivityDecorator
  def new_summary
    metadata.dig("updates", "summary", 1)
  end

  def new_date_decided
    Date.parse(metadata.dig("updates", "date_decided", 1)).to_s(:govuk) rescue nil # rubocop:disable Style/RescueModifier
  end

  def new_legislation
    metadata.dig("updates", "legislation", 1)
  end

  def new_duration
    metadata.dig("updates", "duration", 1)
  end

  def new_details
    metadata.dig("updates", "details", 1)
  end

  def new_measure_type
    metadata.dig("updates", "measure_type", 1)
  end

  def new_geographic_scope
    metadata.dig("updates", "geographic_scope", 1)
  end
end
