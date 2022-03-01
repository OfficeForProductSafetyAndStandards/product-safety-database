class ProductPolicy < ApplicationPolicy
  def export?
    user.all_data_exporter?
  end

  def update?
    record.investigations.none? || Pundit.policy(user, record.investigations.first).update?
  end
end
