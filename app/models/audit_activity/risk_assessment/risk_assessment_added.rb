class AuditActivity::RiskAssessment::RiskAssessmentAdded < AuditActivity::Base
  def self.build_metadata(risk_assessment)
    {
      "risk_assessment" => risk_assessment.attributes.merge(
        "investigation_product_ids" => risk_assessment.investigation_product_ids,
        "risk_assessment_file" => risk_assessment.risk_assessment_file.blob&.attributes
      )
    }
  end

  def subtitle_slug
    "Added"
  end

  def risk_assessment
    RiskAssessment.find(metadata["risk_assessment"]["id"])
  end

  # Some older activities cannot refer to the file as it was not recorded on the activity and may have subsequently been deleted, or the filename recorded on the updated activity was ambiguous
  def risk_assessment_file
    ActiveStorage::Blob.find(metadata["risk_assessment"]["risk_assessment_file"]["id"]) if metadata["risk_assessment"]["risk_assessment_file"]
  end

  def products_assessed
    InvestigationProduct.find(metadata["risk_assessment"]["investigation_product_ids"])
  end

  def further_details
    metadata["risk_assessment"]["details"]
  end

  def risk_level
    metadata["risk_assessment"]["risk_level"]
  end

  def custom_risk_level
    metadata["risk_assessment"]["custom_risk_level"]
  end

  def assessed_on
    Date.parse(metadata["risk_assessment"]["assessed_on"])
  end

  def assessed_by_team
    Team.find_by(id: metadata["risk_assessment"]["assessed_by_team_id"])
  end

  def assessed_by_business
    Business.find_by(id: metadata["risk_assessment"]["assessed_by_business_id"])
  end
end
