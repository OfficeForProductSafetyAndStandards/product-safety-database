class AuditActivity::RiskAssessment::RiskAssessmentAdded < AuditActivity::Base
  def self.from(*)
    raise "Deprecated - use AddRiskAssessmentToCase.call instead"
  end

  def self.build_metadata(risk_assessment)
    {
      risk_assessment_id: risk_assessment.id,
      assessed_on: risk_assessment.assessed_on,
      risk_level: risk_assessment.risk_level,
      custom_risk_level: risk_assessment.custom_risk_level,
      assessed_by_team_id: risk_assessment.assessed_by_team_id,
      assessed_by_business_id: risk_assessment.assessed_by_business_id,
      assessed_by_other: risk_assessment.assessed_by_other,
      details: risk_assessment.details,
      product_ids: risk_assessment.product_ids
    }
  end

  def title(*)
    "Risk assessment"
  end

  def subtitle_slug
    "Added"
  end

  def products_assessed
    Product.find(metadata["product_ids"])
  end

  def further_details
    metadata["details"].presence
  end

  def assessed_by_name
    if metadata["assessed_by_team_id"]
      Team.find(metadata["assessed_by_team_id"])&.name
    elsif metadata["assessed_by_business_id"]
      Business.find(metadata["assessed_by_business_id"])&.trading_name
    else
      metadata["assessed_by_other"]
    end
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
