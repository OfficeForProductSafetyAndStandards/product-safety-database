class UserPolicy < ApplicationPolicy
  def export_cases?
    record.is_psd_admin?
  end
end
