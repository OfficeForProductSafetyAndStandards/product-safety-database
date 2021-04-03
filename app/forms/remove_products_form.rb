class RemoveProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :remove_product, :boolean

  validates :remove_product,
            inclusion: { in: %w[true false], message: I18n.t(".remove_product_form.remove_product.inclusion") }
end
