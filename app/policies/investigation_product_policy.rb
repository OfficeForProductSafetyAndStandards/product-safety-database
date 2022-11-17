class InvestigationProductPolicy < ApplicationPolicy
  def remove?
    return false if record.investigation.is_closed?
    return false if record.investigation_closed_at

    true
  end
end
