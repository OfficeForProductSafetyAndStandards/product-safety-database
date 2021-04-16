class AuditActivity::Business::Destroy < AuditActivity::Business::Base
  def self.from(_business, _investigation)
    raise "Deprecated - use RemoveBusinessFromCase.call instead"
  end

private

  def subtitle_slug
    "Business removed"
  end
end
