class RiskValidationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :is_risk_validated, :boolean, default: nil
  attribute :risk_validated_by, :string
  attribute :risk_validated_at, :datetime

  validates :is_risk_validated, inclusion: { in: [true, false], message: "Select yes if you have validated the case risk level" }
end
