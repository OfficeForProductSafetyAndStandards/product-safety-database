class Incident < UnexpectedEvent
  belongs_to :investigation
  belongs_to :product
end
