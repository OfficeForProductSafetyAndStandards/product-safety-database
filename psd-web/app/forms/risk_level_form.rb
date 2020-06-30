class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :risk_level, :string, default: nil
end
