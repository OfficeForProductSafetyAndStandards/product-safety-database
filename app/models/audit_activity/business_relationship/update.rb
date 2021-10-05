class AuditActivity::BusinessRelationship::Update < AuditActivity::Base
  def self.build_metadata(investigation_business)
    {
      investigation_business_id: investigation_business.id,
      updates: investigation_business.previous_changes.slice(:relationship)
    }
  end

  def title(*)
    "Business relationship with #{business_trading_name} updated"
  end

private

  def business_trading_name
    Business.find_by(id: business_id).trading_name
  end
end
