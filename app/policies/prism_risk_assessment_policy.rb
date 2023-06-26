class PrismRiskAssessmentPolicy < ApplicationPolicy
  def index?
    user.is_prism_user?
  end
end
