class AuditActivity::RiskAssessment::RiskAssessmentUpdated < AuditActivity::Base
  def self.from(*)
    raise "Deprecated - use AddRiskAssessmentToCase.call instead"
  end

  def self.build_metadata(risk_assessment:, previous_product_ids:)
    {
      risk_assessment_id: risk_assessment.id,
      updates: risk_assessment.previous_changes.slice(
        :assessed_on,
        :risk_level,
        :custom_risk_level,
        :assessed_by_team_id,
        :assessed_by_business_id,
        :assessed_by_other,
        :details
      ).merge({
        product_ids: [previous_product_ids, risk_assessment.product_ids]
      })
    }
  end

  def risk_level_changed?
    new_risk_level || new_custom_risk_level
  end

  def assessed_by_changed?
    new_assessed_by_team_id || new_assessed_by_business_id || new_assessed_by_other
  end

  def products_changed?
    new_product_ids
  end

  def new_assessed_on
    updates["assessed_on"]&.second
  end

  def new_risk_level
    updates["risk_level"]&.second
  end

  def new_assessed_by_team
    if new_assessed_by_team_id
      Team.find(new_assessed_by_team_id)
    end
  end

  def new_assessed_by_business
    if new_assessed_by_business_id
      Business.find(new_assessed_by_business_id)
    end
  end

  def new_assessed_by_team_id
    updates["assessed_by_team_id"]&.second
  end

  def new_assessed_by_business_id
    updates["assessed_by_business_id"]&.second
  end

  def new_assessed_by_other
    updates["assessed_by_other"]&.second
  end

  def new_custom_risk_level
    updates["custom_risk_level"]&.second
  end

  def new_product_ids
    updates["product_ids"]&.second
  end

  def new_products
    Product.find(new_product_ids)
  end

  def new_details
    updates["details"]&.second
  end

  def risk_assessment_id
    metadata["risk_assessment_id"]
  end

  def title(_)
    "Risk assessment edited"
  end

  def subtitle_slug
    "Edited"
  end

  def products_assessed
    Product.find(metadata["product_ids"])
  end

  def further_details
    metadata["details"].presence
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end

private

  def updates
    metadata["updates"]
  end
end
