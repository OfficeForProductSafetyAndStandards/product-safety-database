class AddAnotherRiskAssessmentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :add_another_risk_assessment
  validates :add_another_risk_assessment, presence: true
end
