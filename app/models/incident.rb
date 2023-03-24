class Incident < UnexpectedEvent
  belongs_to :investigation
  belongs_to :investigation_product
end
