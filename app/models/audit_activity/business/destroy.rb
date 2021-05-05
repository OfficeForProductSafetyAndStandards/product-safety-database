class AuditActivity::Business::Destroy < AuditActivity::Base
  belongs_to :business, class_name: "::Business"

  def self.build_metadata(business, reason)
    { reason: reason, business: business.attributes }
  end

  def self.from(_business, _investigation)
    raise "Deprecated - use RemoveBusinessFromCase.call instead"
  end

  def migrate_to_metadata
    update!(metadata: { business: business.attributes })
  end

private

  def subtitle_slug
    "Business removed"
  end

  def notify_relevant_users; end
end
