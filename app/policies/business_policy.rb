class BusinessPolicy < ApplicationPolicy
  def export?
    user.is_psd_admin?
  end
end
