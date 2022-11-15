class InvestigationProductPolicy < ApplicationPolicy
  def remove_product?
    return false if record.investigation.is_closed?
    return false if record.investigation_closed_at

    true
  end
end
