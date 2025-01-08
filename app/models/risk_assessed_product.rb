class RiskAssessedProduct < ApplicationRecord
  belongs_to :risk_assessment
  belongs_to :investigation_product

  redacted_export_with :id, :created_at, :investigation_product_id, :risk_assessment_id, :updated_at
end
