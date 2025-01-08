class FindProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks

  attribute :reference, :string
  attribute :investigation

  before_validation :unset_product
  before_validation :tidy_reference, if: -> { reference.present? }

  validates :reference, numericality: { only_integer: true, greater_than: 0, message: "Enter a PSD product record reference number" }
  validate :must_find_a_product
  validate :must_not_find_a_product_already_linked

  def product
    return @product if @product.present?

    product_id = reference.presence && reference.try(:to_i)
    return nil unless product_id && product_id.positive?

    @product = Product.not_retired.find_by id: product_id
  end

private

  def unset_product
    @product = nil
  end

  def tidy_reference
    reference.strip!
    reference.sub!(/\Apsd-/i, "")
    reference.strip!
  end

  def must_find_a_product
    return if errors.include?(:reference)

    errors.add(:reference, "An active product record matching psd-#{reference} does not exist") if product.blank?
  end

  def must_not_find_a_product_already_linked
    return if errors.include?(:reference)

    errors.add(:reference, "Enter a product record which has not already been added to the notification") if product.present? && duplicate_investigation_product
  end

  def duplicate_investigation_product
    InvestigationProduct.find_by(product_id: product.id, investigation_id: investigation.id, investigation_closed_at: investigation.date_closed)
  end
end
