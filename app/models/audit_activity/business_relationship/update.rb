class AuditActivity::BusinessRelationship::Update < AuditActivity::Base
  def self.build_metadata(investigation_business)
    {
      investigation_business_id: investigation_business.id,
      updates: investigation_business.previous_changes.slice(:relationship)
    }
  end

  def title(*)
    "Business relationship updated"
  end
end
