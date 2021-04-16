class RemoveProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :remove_product, :boolean
  attribute :reason

  validates :remove_product, inclusion: { in: [true, false] }
  validates :reason, presence: true, if: -> { remove_product }
end
