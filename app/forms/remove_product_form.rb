class RemoveProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :remove_product, :boolean
  attribute :reason

  validates :remove_product,
            inclusion: { in: [true, false], message: I18n.t(".remove_product_form.attributes.remove_product.inclusion") }
end
