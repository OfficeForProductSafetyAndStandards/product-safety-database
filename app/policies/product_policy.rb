class ProductPolicy < ApplicationPolicy
  def export?
    user.is_psd_admin?
  end

  def update?
    record.investigations.none? || Pundit.policy(user, record.investigations.first).update?
  end
end
