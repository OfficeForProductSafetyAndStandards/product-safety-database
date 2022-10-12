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
end
