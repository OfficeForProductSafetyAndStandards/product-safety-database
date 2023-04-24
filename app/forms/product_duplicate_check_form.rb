class ProductDuplicateCheckForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :barcode
  attribute :has_barcode, :boolean

  validates :has_barcode, inclusion: { in: [true, false] }
  validates :barcode, numericality: { only_integer: true }, if: -> { has_barcode }
  validates :barcode, length: { minimum: 5, maximum: 15 }, if: -> { has_barcode && barcode =~ /\A\d+\z/ }

  before_validation :strip_barcode

  def strip_barcode
    self.barcode = barcode.strip if barcode.present?
  end
end
