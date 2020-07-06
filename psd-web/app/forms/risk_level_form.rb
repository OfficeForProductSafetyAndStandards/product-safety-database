class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  OTHER = "other".freeze
  ALLOWED_LEVELS = Investigation::STANDARD_RISK_LEVELS + [OTHER]

  attr_reader :original_level, :original_level_other

  attribute :risk_level, :string, default: nil
  attribute :risk_level_other, :string, default: nil

  validate :risk_level_allowed_validation
  validate :risk_level_other_present_validation

  def initialize(attributes)
    @original_level = normalise(attributes[:risk_level])
    @original_level_other = normalise(attributes[:risk_level_other])
    attrs = set_attributes
    super(attrs)
  end

private

  def set_attributes
    attrs = {}
    if original_level == OTHER
      attrs[:risk_level] = original_level_other
    elsif set_other_from_risk_level?
      attrs[:risk_level_other] = original_level
      attrs[:risk_level] = OTHER
    else
      attrs[:risk_level] = original_level
    end
    attrs
  end

  def risk_level_allowed_validation
    if original_level.present? && !matching_level_in_list(original_level, ALLOWED_LEVELS)
      errors.add(:risk_level, :not_allowed)
      restore_originals
    end
  end

  def risk_level_other_present_validation
    if original_level == OTHER && original_level_other.blank?
      errors.add(:risk_level_other, :blank)
      restore_originals
    end
  end

  def set_other_from_risk_level?
    original_level.present? && !matching_level_in_list(original_level, Investigation::STANDARD_RISK_LEVELS)
  end

  def restore_originals
    self.risk_level = original_level
    self.risk_level_other = original_level_other
  end

  def equal_levels?(first_level, second_level)
    first_level.delete(" ").casecmp(
      second_level.delete(" ")
    ).zero?
  end

  def matching_level_in_list(level, list)
    return if level.blank?

    list.find { |elem| equal_levels?(elem, level) }
  end

  def normalise(level)
    matching_level_in_list(level, Investigation::STANDARD_RISK_LEVELS).presence || level
  end
end
