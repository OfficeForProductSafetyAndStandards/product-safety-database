# Plain Old Ruby Object
# Compares investigation current risk and custom risk levels against new
# risk level and custom risk level, providing information about what action
# (if any) will be resulting from the change.
class Investigation::RiskLevelChange
  attr_reader :current_level, :current_custom, :new_level, :new_custom

  def initialize(investigation, changes)
    @current_level = investigation.risk_level
    @current_custom = investigation.custom_risk_level
    @new_level = new_level
    @new_custom = new_custom
  end

  def change_action
    if !any_changes? then nil
    elsif set? then :set
    elsif remove? then :removed
    else :changed
    end
  end

private

  def new_level_accepted?
    new_level.blank? || Investigation.risk_levels.key?(new_level.to_s)
  end

  def risk_level_changes?
    return false unless new_level_accepted?

    current_level.to_s != new_level.to_s
  end

  def custom_risk_level_changes?
    current_custom.to_s != new_custom.to_s
  end

  def any_changes?
    risk_level_changes? || custom_risk_level_changes?
  end

  def set?
    any_changes? && current_level.blank? && current_custom.blank?
  end

  def remove?
    any_changes? && new_level.blank? && new_custom.blank?
  end
end
