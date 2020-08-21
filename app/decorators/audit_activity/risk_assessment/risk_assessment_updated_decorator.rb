class AuditActivity::RiskAssessment::RiskAssessmentUpdatedDecorator < ApplicationDecorator
  delegate_all

  def new_risk_level_description
    if new_risk_level.present? && new_risk_level != "other"
      I18n.t(".investigations.risk_level.show.levels.#{new_risk_level}")
    else
      new_custom_risk_level
    end
  end
end
