class ConfirmProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :product_id, :integer
  attribute :correct, :string

  validates :correct, inclusion: { in: %w[yes no], message: "Select yes if this is the correct product record to add to your case" }

  def self.from_find_product_form(find_product_form)
    new product_id: find_product_form.product&.id
  end

  def product
    Product.find product_id
  end
end
