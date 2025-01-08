class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :risk_level, :string, default: nil

  validates_inclusion_of :risk_level, in: (Investigation.risk_levels.values - [Investigation.risk_levels[:other]]), if: -> { risk_level.present? }
end
