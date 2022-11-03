class ProductPolicy < ApplicationPolicy
  def export?
    user.all_data_exporter?
  end

  def update?
    record.version.nil? && (record.owning_team.nil? || record.owning_team == user.team)
  end
end
