class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  OTHER = "other".freeze

  attribute :risk_level, :string, default: nil
  attribute :risk_level_other, :string, default: nil

  def initialize(attributes)
    risk_level = attributes[:risk_level]
    risk_level_other = attributes[:risk_level_other]

    if risk_level == OTHER
      attributes[:risk_level] = risk_level_other
    elsif set_other_from_risk_level?(risk_level)
      attributes[:risk_level_other] = risk_level
      attributes[:risk_level] = OTHER
    else
      attributes[:risk_level_other] = nil
    end

    super
  end

private

  def set_other_from_risk_level?(risk_level)
    risk_level.present? && !standard_risk_level?(risk_level)
  end

  def standard_risk_level?(risk_level)
    Investigation::STANDARD_RISK_LEVELS.include? risk_level
  end
end
