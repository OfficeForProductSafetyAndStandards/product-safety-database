class MigrateMetadataForAuditTrails
  include Interactor

  def call
    migrate_risk_assessments_added!
    migrate_risk_assessments_updated!
    migrate_accident_or_incident_updated!
    migrate_corrective_action_updated!
    migrate_corrective_action_added!
    migrate_test_result_activity!
    migrate_test_result_updated_activity!
  end

private

  def migrate_risk_assessments_added!
    AuditActivity::RiskAssessment::RiskAssessmentAdded.all.each do |object|
      product_ids = object.metadata.dig("risk_assessment", "product_ids")
      next if product_ids.blank?

      object.metadata["risk_assessment"]["investigation_product_ids"] = investigation_product_ids(investigation: object.investigation, product_ids:)
      object.save!
    end
  end

  def migrate_risk_assessments_updated!
    AuditActivity::RiskAssessment::RiskAssessmentUpdated.all.each do |object|
      product_ids = object.metadata["previous_product_ids"]
      next if product_ids.blank?

      object.metadata["previous_investigation_product_ids"] = investigation_product_ids(investigation: object.investigation, product_ids:)
      object.save!
    end
  end

  def migrate_accident_or_incident_updated!
    AuditActivity::AccidentOrIncident::AccidentOrIncidentUpdated.all.each do |object|
      product_id = object.metadata.dig("updates", "product_id")
      next if product_id.blank?

      object.metadata["updates"]["investigation_product_id"] = investigation_product_id(investigation: object.investigation, product_id:)
      object.save!
    end
  end

  def migrate_corrective_action_updated!
    AuditActivity::CorrectiveAction::Update.all.each do |object|
      product_id = object.metadata.dig("updates", "product_id")
      next if product_id.blank?

      object.metadata["updates"]["investigation_product_id"] = investigation_product_id(investigation: object.investigation, product_id:)
      object.save!
    end
  end

  def migrate_corrective_action_added!
    AuditActivity::CorrectiveAction::Add.all.each do |object|
      product_id = object.metadata.dig("corrective_action", "product_id")
      next if product_id.blank?

      object.metadata["corrective_action"]["investigation_product_id"] = investigation_product_id(investigation: object.investigation, product_id:)
      object.save!
    end
  end

  def migrate_test_result_activity!
    AuditActivity::Test::Result.all.each do |object|
      product_id = object.metadata.dig("test_result", "product_id")
      next if product_id.blank?

      object.metadata["test_result"]["investigation_product_id"] = investigation_product_id(investigation: object.investigation, product_id:)
      object.save!
    end
  end

  def migrate_test_result_updated_activity!
    AuditActivity::Test::TestResultUpdated.all.each do |object|
      product_id = object.metadata.dig("updates", "product_id")
      next if product_id.blank?

      object.metadata["updates"]["investigation_product_id"] = investigation_product_id(investigation: object.investigation, product_id:)
      object.save!
    end
  end

  def investigation_product_ids(investigation:, product_ids:)
    investigation.investigation_products.where(product_id: product_ids).pluck("investigation_products.id")
  end

  def investigation_product_id(investigation:, product_id:)
    investigation.investigation_products.where(product_id:).pick("investigation_products.id")
  end
end
