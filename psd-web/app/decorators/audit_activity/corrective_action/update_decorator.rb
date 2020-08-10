class AuditActivity::CorrectiveAction::UpdateDecorator < AuditActivity::CorrectiveAction::BaseDecorator
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

  def new_filename
    metadata.dig("updates", "filename", 1)
  end

  def old_filename
    metadata.dig("updates", "filename", 0)
  end

  def new_file_description
    metadata.dig("updates", "file_description", 1)
  end

  def product_updated?
    metadata.dig("updates", "product_id", 1)
  end

  def business_updated?
    metadata.dig("updates", "business_id", 1)
  end
end
