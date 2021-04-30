class AuditActivity::Business::Add < AuditActivity::Base
  belongs_to :business

  def self.build_metadata(business, business_investigation)
    { business: business.attributes, investigation_business: business_investigation.attributes }
  end

  def self.from(*)
    raise "Deprecated - use AddBusinessToCase.call instead"
  end

private

  def notify_relevant_users; end
end
