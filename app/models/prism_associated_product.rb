class PrismAssociatedProduct < ApplicationRecord
  belongs_to :prism_risk_assessment, foreign_key: "risk_assessment_id"
  belongs_to :product
end
