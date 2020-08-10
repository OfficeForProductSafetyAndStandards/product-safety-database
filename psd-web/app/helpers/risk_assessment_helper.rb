module RiskAssessmentHelper
  def risk_assessed_by(risk_assessment)
    if risk_assessment.assessed_by_team
      risk_assessment.assessed_by_team.name
    elsif risk_assessment.assessed_by_business
      link_to risk_assessment.assessed_by_business.trading_name, risk_assessment.assessed_by_business
    else
      risk_assessment.assessed_by_other
    end
  end
end
