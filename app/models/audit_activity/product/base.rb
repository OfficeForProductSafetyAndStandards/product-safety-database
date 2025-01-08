class AuditActivity::Product::Base < AuditActivity::Base
  validates :investigation_product, presence: true
end
