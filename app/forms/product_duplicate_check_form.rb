class ProductDuplicateCheckForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :barcode
  attribute :has_barcode, :boolean

  validates :has_barcode, inclusion: { in: [true, false] }
  validates :barcode, length: { minimum: 5, maximum: 25 }, presence: true, if: -> { has_barcode == true }

  before_validation :strip_barcode

  def strip_barcode
    return if barcode.blank?

    self.barcode = barcode.strip
  end
end
