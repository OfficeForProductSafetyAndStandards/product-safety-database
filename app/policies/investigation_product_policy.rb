class InvestigationProductPolicy < ApplicationPolicy
  def remove?(user: @user)
    return false if record.investigation.is_closed?
    return false if record.investigation_closed_at
    InvestigationPolicy.new(@user, record.investigation).update?
  end
end
