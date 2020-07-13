class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  STANDARD_LEVELS = Investigation.risk_levels.values - [Investigation.risk_levels[:other]]

  attribute :risk_level, :string, default: nil
  attribute :custom_risk_level, :string, default: nil

  validates_inclusion_of :risk_level, in: Investigation.risk_levels.values, if: -> { risk_level.present? }
  validates_presence_of :custom_risk_level, if: -> { risk_level == Investigation.risk_levels[:other] }

  def attributes
    if STANDARD_LEVELS.include?(computed_custom_risk_level)
      {
        risk_level: computed_custom_risk_level,
        custom_risk_level: nil
      }
    else
      {
        risk_level: computed_risk_level,
        custom_risk_level: risk_level_other? ? custom_risk_level : nil
      }

    end
  end

private

  def computed_risk_level
    return computed_custom_risk_level if STANDARD_LEVELS.include?(custom_risk_level)

    risk_level
  end

  def computed_custom_risk_level
    @computed_custom_risk_level ||= custom_risk_level&.downcase&.squish
  end

  def risk_level_other?
    risk_level == Investigation.risk_levels[:other]
  end
end
