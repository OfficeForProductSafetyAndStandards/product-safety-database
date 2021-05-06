class AuditActivity::RiskAssessment::RiskAssessmentAddedDecorator < ApplicationDecorator
  delegate_all

  def title(*)
    "Risk assessment"
  end

  def assessed_on
    object.assessed_on.to_s(:govuk)
  end

  def risk_level
    return object.custom_risk_level if object.custom_risk_level.present?

    I18n.t(".investigations.risk_level.show.levels.#{object.risk_level}")
  end

  def assessed_by_name
    return object.assessed_by_team.name if object.assessed_by_team
    return object.assessed_by_business.trading_name if object.assessed_by_business

    object.metadata["risk_assessment"]["assessed_by_other"]
  end

  def products_assessed
    object.products_assessed.collect(&:name).to_sentence
  end
end
