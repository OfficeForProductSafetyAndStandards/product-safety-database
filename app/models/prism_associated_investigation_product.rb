class PrismAssociatedInvestigationProduct < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to assign new
  # associated investigation products.
  def readonly?
    true
  end

  belongs_to :product
end
