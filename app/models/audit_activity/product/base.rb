class AuditActivity::Product::Base < AuditActivity::Base
  validates :product, presence: true
end
