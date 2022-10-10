class FindProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks

  attribute :reference, :string
  attribute :investigation

  before_validation :tidy_reference

  validates :reference, presence: { message: "Enter a PSD product record reference number" }, numericality: { only_integer: true, greater_than: 0, message: "Enter a PSD product record reference number" }
  validate :must_find_a_product
  validate :must_not_find_a_product_already_linked

  def product
    product_id = reference.presence && reference.try(:to_i)
    return nil unless product_id && product_id.positive?

    Product.find_by id: product_id
  end

private

  def tidy_reference
    return if reference.blank?

    reference.sub!(/\Apsd-/i, "")
    reference.strip!
  end

  def must_find_a_product
    errors.add(:reference, "An active product record matching psd-#{reference} does not exist") if product.blank?
  end

  def must_not_find_a_product_already_linked
    errors.add(:reference, "Enter a product record which has not already been added to the case") if product.present? && investigation.products.include?(product)
  end
end
