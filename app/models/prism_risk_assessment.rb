class PrismRiskAssessment < ApplicationRecord
  # This model is only used for the PRISM risk assessment
  # dashboard inside PSD and cannot be used to create new
  # PRISM risk assessments. Creation and editing is handled
  # by the PRISM engine using the `Prism::RiskAssessment` model.
  def readonly?
    true
  end

  has_one :prism_product, foreign_key: "risk_assessment_id"
  has_many :prism_harm_scenarios, foreign_key: "risk_assessment_id"

  scope :for_user, ->(user) { where(created_by_user_id: user.id) }
  scope :draft, -> { where(state: "draft") }
  scope :submitted, -> { where(state: "submitted") }
end