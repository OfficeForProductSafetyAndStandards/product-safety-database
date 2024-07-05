class SearchForOrAddAProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :add_another_product
  validates :add_another_product, presence: true
end
