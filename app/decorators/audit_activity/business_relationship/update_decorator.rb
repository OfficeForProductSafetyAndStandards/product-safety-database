class AuditActivity::BusinessRelationship::UpdateDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def relationship_changed?
    new_relationship
  end

  def new_relationship
    metadata.dig("updates", "relationship", 1)
  end

  def business
    InvestigationBusiness.find(metadata["investigation_business_id"]).business
  end
end
