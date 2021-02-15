class ProductPolicy < ApplicationPolicy
  def export?
    user.is_psd_admin?
  end
end
