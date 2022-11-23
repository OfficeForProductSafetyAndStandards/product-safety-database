class ProductPolicy < ApplicationPolicy
  def show?
    return true if record.not_retired?

    user.is_opss?
  end

  def export?
    user.all_data_exporter?
  end

  def update?
    return false if record.version.present?
    return false if record.retired? && !user.is_opss?

    record.owning_team.nil? || record.owning_team == user.team
  end

  def can_spawn_case?
    !user.is_opss? && record.not_retired?
  end
end
