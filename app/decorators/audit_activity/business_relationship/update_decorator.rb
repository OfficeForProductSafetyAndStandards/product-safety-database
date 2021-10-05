class AuditActivity::BusinessRelationship::UpdateDecorator < AuditActivity::CorrectiveAction::BaseDecorator
  def relationship_changed?
    metadata.dig("updates", "relationship", 1)
  end

  def new_relationship
    I18n.t(".business.type.#{metadata.dig("updates", "relationship", 1)}", default: metadata.dig("updates", "relationship", 1).capitalize)
  end

  def business
    InvestigationBusiness.find(metadata["investigation_business_id"]).business
  end
end
