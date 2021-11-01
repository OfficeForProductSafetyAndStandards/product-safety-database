class RiskAssessedProduct < ApplicationRecord
  belongs_to :risk_assessment
  belongs_to :product

  redacted_export_with :id, :created_at, :product_id, :risk_assessment_id, :updated_at
end
