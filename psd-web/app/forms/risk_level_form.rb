class RiskLevelForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  OTHER = "other".freeze
  STANDARD_LEVELS = Investigation.risk_levels.keys
  ALLOWED_LEVELS = STANDARD_LEVELS + [OTHER]

  attribute :risk_level, :string, default: nil
  attribute :custom_risk_level, :string, default: nil

  validate :risk_level_allowed_validation
  validate :custom_risk_level_present_validation

  def initialize(attributes)
    # With a valid risk level selection we ignore/override the custom field
    # as both fields exclude each other and risk level selection takes priority.
    if STANDARD_LEVELS.include? attributes[:risk_level]
      attributes[:custom_risk_level] = nil
    elsif attributes[:custom_risk_level].present?
      # When the custom level introduced by the user matches a standard risk
      # level, it becomes the selected risk level instead of being stored in the
      # custom field.
      if (match = displayed_standard_level_match_with(attributes[:custom_risk_level]))
        attributes[:risk_level] = displayed_levels.key(match)
        attributes[:custom_risk_level] = nil
      # When loading custom risk level from DB, the empty risk level needs to be set
      # as "other" so the custom field is displayed in the form.
      elsif attributes[:risk_level].blank?
        attributes[:risk_level] = OTHER
      end
    end
    super(attributes)
  end

private

  def risk_level_allowed_validation
    if risk_level.present? && !matching_level_in_list(risk_level, ALLOWED_LEVELS)
      errors.add(:risk_level, :not_allowed)
    end
  end

  def custom_risk_level_present_validation
    if risk_level == OTHER && custom_risk_level.blank?
      errors.add(:custom_risk_level, :blank)
    end
  end

  def equal_levels?(first_level, second_level)
    first_level.strip.casecmp(
      second_level.strip
    ).zero?
  end

  def matching_level_in_list(level, list)
    return if level.blank?

    list.find { |elem| equal_levels?(elem, level) }
  end

  def displayed_standard_level_match_with(level)
    matching_level_in_list(level, displayed_levels.values).presence
  end

  def displayed_levels
    @displayed_levels ||= STANDARD_LEVELS.each_with_object({}) do |level, hash|
      hash[level] = I18n.t(".investigations.risk_level.show.levels.#{level}")
    end
  end
end
