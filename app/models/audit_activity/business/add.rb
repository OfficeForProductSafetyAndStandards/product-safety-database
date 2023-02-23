class AuditActivity::Business::Add < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, business_investigation)
    { business: business.attributes, investigation_business: business_investigation.attributes }
  end

end
