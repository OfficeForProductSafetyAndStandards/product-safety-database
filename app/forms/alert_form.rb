class AlertForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :summary
  attribute :description
  attribute :user_count

  validates :summary, presence: true
  validates :description, length: { maximum: 10_000 }

  def default_summary
    "Product safety alert: "
  end

  def default_description
    "\r\n\r\n\r\nMore details can be found on the case page: "
  end
end
