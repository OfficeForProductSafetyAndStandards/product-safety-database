class AuditActivity::Product::Base < AuditActivity::Base
  validates :product, presence: true

  # Do not send investigation_updated mail when product added/removed. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
