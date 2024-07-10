class SelectProductForPrismForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :product_id
  validates :product_id, presence: true
end
