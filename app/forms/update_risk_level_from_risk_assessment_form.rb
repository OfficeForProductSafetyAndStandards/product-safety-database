class UpdateRiskLevelFromRiskAssessmentForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :update_case_risk_level_to_match_investigation, :boolean, default: nil

  validates :update_case_risk_level_to_match_investigation, inclusion: { in: [true, false] }
end
