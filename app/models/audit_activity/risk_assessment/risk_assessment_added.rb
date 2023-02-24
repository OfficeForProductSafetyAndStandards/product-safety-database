class AuditActivity::RiskAssessment::RiskAssessmentAdded < AuditActivity::Base
  def self.build_metadata(risk_assessment)
    { "risk_assessment" => risk_assessment.attributes.merge(
      "investigation_product_ids" => risk_assessment.investigation_product_ids,
      "risk_assessment_file" => risk_assessment.risk_assessment_file.blob&.attributes
    ) }
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
    Product.find(metadata["risk_assessment"]["product_ids"])
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

private

  # Migrates metadata from old structure to current. This method can be deleted once data is migrated.
  # TODO: Remove method once data migrated
  #
  # Old structure:
  #
  # {
  #   risk_assessment_id: risk_assessment.id,
  #   assessed_on: risk_assessment.assessed_on,
  #   risk_level: risk_assessment.risk_level,
  #   custom_risk_level: risk_assessment.custom_risk_level,
  #   assessed_by_team_id: risk_assessment.assessed_by_team_id,
  #   assessed_by_business_id: risk_assessment.assessed_by_business_id,
  #   assessed_by_other: risk_assessment.assessed_by_other,
  #   details: risk_assessment.details,
  #   product_ids: risk_assessment.product_ids
  # }
  def migrate_metadata_structure
    metadata = self[:metadata]

    # Already in new format
    return metadata if metadata["risk_assessment"].present?

    risk_assessment = RiskAssessment.find(metadata["risk_assessment_id"])

    # ID must be cast to String to avoid SQL error querying JSON column
    risk_assessment_updated = AuditActivity::RiskAssessment::RiskAssessmentUpdated.where("metadata->'risk_assessment_id' = ?", risk_assessment.id.to_s).any?

    if risk_assessment_updated
      # We cannot reliably find the old file since orphaned files were
      # previously deleted and there are a large proportion of records with
      # ambiguous filenames.
      new_risk_assessment_file = nil
      new_updated_at = updated_at
    else
      # If the risk assessment has not been updated we can safely assume the
      # file has not changed since it was added
      new_risk_assessment_file = risk_assessment.risk_assessment_file.blob&.attributes
      new_updated_at = risk_assessment.updated_at
    end

    {
      "risk_assessment" => {
        "id" => metadata["risk_assessment_id"],
        "investigation_id" => risk_assessment.investigation_id,
        "assessed_on" => metadata["assessed_on"],
        "assessed_by_team_id" => metadata["assessed_by_team_id"],
        "assessed_by_business_id" => metadata["assessed_by_business_id"],
        "assessed_by_other" => metadata["assessed_by_other"],
        "details" => metadata["details"],
        "custom_risk_level" => metadata["custom_risk_level"],
        "added_by_user_id" => risk_assessment.added_by_user_id,
        "added_by_team_id" => risk_assessment.added_by_team_id,
        "created_at" => risk_assessment.created_at,
        "updated_at" => new_updated_at,
        "risk_level" => metadata["risk_level"],
        "product_ids" => metadata["product_ids"],
        "risk_assessment_file" => new_risk_assessment_file
      }
    }
  end
end
