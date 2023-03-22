class AuditActivity::Investigation::UpdateCaseSpecificProductInformationDecorator < ApplicationDecorator
  delegate_all

  def new_batch_number
    metadata.dig("updates", "batch_number", 1)
  end

  def new_customs_code
    metadata.dig("updates", "customs_code", 1)
  end

  def title(_viewer)
    "Case specific product information updated"
  end

  def new_number_of_affected_units
    metadata.dig("updates", "number_of_affected_units", 1)
  end

  def new_affected_units_status
    metadata.dig("updates", "affected_units_status", 1)
  end
end
