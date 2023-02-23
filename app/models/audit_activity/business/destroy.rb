class AuditActivity::Business::Destroy < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, reason)
    { reason:, business: business.attributes }
  end

  def subtitle_slug
    "Business removed"
  end
end
