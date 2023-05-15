class AuditActivity::RiskAssessment::RiskAssessmentUpdatedDecorator < ApplicationDecorator
  delegate_all

  def new_risk_level_description
    I18n.t(".investigations.risk_level.show.levels.#{new_risk_level}")
  end
end
