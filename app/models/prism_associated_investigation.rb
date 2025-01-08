class PrismAssociatedInvestigation < ApplicationRecord
  belongs_to :prism_risk_assessment, foreign_key: "risk_assessment_id"
  has_many :prism_associated_investigation_products, foreign_key: "associated_investigation_id"

  accepts_nested_attributes_for :prism_associated_investigation_products, reject_if: :all_blank
end
