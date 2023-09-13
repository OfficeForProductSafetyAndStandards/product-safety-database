class PrismAssociatedInvestigation < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to assign new
  # associated investigations.
  def readonly?
    true
  end

  has_many :prism_associated_investigation_products, foreign_key: "associated_investigation_id"
end
