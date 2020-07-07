class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  OTHER = "other".freeze
  ALLOWED_LEVELS = Investigation::STANDARD_RISK_LEVELS + [OTHER]

  attr_reader :input_level, :input_other

  attribute :risk_level, :string, default: nil
  attribute :risk_level_other, :string, default: nil

  validate :input_level_allowed_validation
  validate :input_other_present_validation

  def initialize(attributes)
    @input_level = normalise(attributes[:risk_level])
    @input_other = normalise(attributes[:risk_level_other])
    attrs = set_attributes
    super(attrs)
  end

private

  # Transforms in 2 directions:
  # 1. User selection/input (risk_level and risk_level_other) into risk_level stored in DB.
  # 2. DB risk_level value into risk_level and risk_level other to be displayed in the form.
  def set_attributes
    attrs = {}
    # User selected "other" in the risk level selection and filled the custom input field
    if input_level == OTHER
      attrs[:risk_level] = input_other
    # Building the form from DB value coming from 'risk_level' field
    elsif other_set_as_risk_level?
      attrs[:risk_level_other] = input_level
      attrs[:risk_level] = OTHER
    # Just sets the risk level from the selection or from DB value
    else
      attrs[:risk_level] = input_level
    end
    attrs
  end

  def input_level_allowed_validation
    if input_level.present? && !matching_level_in_list(input_level, ALLOWED_LEVELS)
      errors.add(:risk_level, :not_allowed)
      restore_inputs # To display the invalid inputs with the errors.
    end
  end

  def input_other_present_validation
    if input_level == OTHER && input_other.blank?
      errors.add(:risk_level_other, :blank)
      restore_inputs
    end
  end

  def other_set_as_risk_level?
    input_level.present? && !matching_level_in_list(input_level, Investigation::STANDARD_RISK_LEVELS)
  end

  def restore_inputs
    self.risk_level = input_level
    self.risk_level_other = input_other
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
