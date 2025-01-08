class BusinessPolicy < ApplicationPolicy
  def export?
    user.all_data_exporter?
  end
end
