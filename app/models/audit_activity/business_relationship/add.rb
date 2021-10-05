class AuditActivity::BusinessRelationship::Add < AuditActivity::Base
  def self.build_metadata(investigation_business)
    {
      investigation_business_id: investigation_business.id,
      relationship: investigation_business.relationship,
      trading_name: investigation_business.business.trading_name
    }
  end

  def title(*)
    "Business added to case"
  end
end
