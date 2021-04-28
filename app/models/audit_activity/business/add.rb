class AuditActivity::Business::Add < AuditActivity::Business::Base
  belongs_to :business
  def self.build_metadata(business)
    { business: business.attributes }
  end

  def self.from(*)
    raise "Deprecated - use AddBusinessToCase.call instead"
  end
end
