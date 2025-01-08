module RiskAssessmentHelper
  def risk_assessed_by(team:, business:, other:)
    if team
      team.name
    elsif business
      link_to(business.trading_name, business)
    else
      other
    end
  end
end
