class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  OTHER = "other".freeze
  ALLOWED_LEVELS = Investigation::STANDARD_RISK_LEVELS + [OTHER]

  attr_reader :original_level, :original_level_other

  attribute :risk_level, :string, default: nil
  attribute :risk_level_other, :string, default: nil

  validate :risk_level_allowed
  validate :risk_level_other_present

  def initialize(attributes)
    @original_level = attributes[:risk_level]
    @original_level_other = attributes[:risk_level_other]
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

  def risk_level_allowed
    if original_level.present? && !ALLOWED_LEVELS.include?(original_level)
      errors.add(:risk_level, :not_allowed)
      restore_originals
    end
  end

  def risk_level_other_present
    if original_level == OTHER && original_level_other.blank?
      errors.add(:risk_level_other, :blank)
      restore_originals
    end
  end

  def set_other_from_risk_level?
    original_level.present? && !Investigation::STANDARD_RISK_LEVELS.include?(original_level)
  end

  def restore_originals
    self.risk_level = original_level
    self.risk_level_other = original_level_other
  end
end
