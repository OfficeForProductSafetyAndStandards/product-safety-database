class RiskAssessedProduct < ApplicationRecord
  belongs_to :risk_assessment
  belongs_to :product
end
