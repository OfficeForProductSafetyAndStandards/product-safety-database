class AuditActivity::Business::Destroy < AuditActivity::Business::Base
  def self.build_metadata(business, reason)
    { reason: reason, business: business.attributes }
  end

  def self.from(_business, _investigation)
    raise "Deprecated - use RemoveBusinessFromCase.call instead"
  end

private

  def subtitle_slug
    "Business removed"
  end

  def notify_relevant_users; end
end
