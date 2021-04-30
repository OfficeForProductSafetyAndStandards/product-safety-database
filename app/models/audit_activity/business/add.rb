class AuditActivity::Business::Add < AuditActivity::Base
  belongs_to :business

  def self.build_metadata(business, business_investigation)
    { business: business.attributes, investigation_business: business_investigation.attributes }
  end

  def self.from(*)
    raise "Deprecated - use AddBusinessToCase.call instead"
  end

  def migrate_to_metadata
    self.metadata = {
      business: { trading_name: title },
      investigation_business: { relationship: body.match(/Role: \*\*(?<relationship>.*)\*\*/)["relationship"].delete("\\") }
    }
    save!
  end

private

  def notify_relevant_users; end
end
