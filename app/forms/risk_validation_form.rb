class RiskValidationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :is_risk_validated, :boolean, default: nil
end
