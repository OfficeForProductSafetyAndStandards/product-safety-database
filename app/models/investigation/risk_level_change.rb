# Plain Old Ruby Object
# Compares investigation current risk and custom risk levels against new
# risk level and custom risk level, providing information about what action
# (if any) will be resulting from the change.
class Investigation::RiskLevelChange
  def initialize(investigation)
    self.investigation = investigation
  end

  def change_action
    if !any_changes? then nil
    elsif set? then :set
    elsif remove? then :removed
    else
      :changed
    end
  end

private

  attr_accessor :investigation

  def any_changes?
    investigation.risk_level_changed?
  end

  def set?
    any_changes? && investigation.risk_level_was.blank?
  end

  def remove?
    any_changes? && investigation.risk_level.blank?
  end
end
