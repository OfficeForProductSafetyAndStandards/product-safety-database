class ProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include SanitizationHelper

  attribute :authenticity
  attribute :batch_number
  attribute :brand
  attribute :category
  attribute :country_of_origin
  attribute :description
  attribute :gtin13
  attribute :name
  attribute :product_code
  attribute :product_type
  attribute :webpage

  before_validation { trim_line_endings(:description) }
  before_validation { convert_gtin_to_13_digits(:gtin13) }
  before_validation { trim_whitespace(:brand) }
  before_validation { nilify_blanks(:gtin13, :brand) }

  validates :gtin13, allow_nil: true, length: { is: 13 }, gtin: true
  validates :authenticity, inclusion: { in: Product.authenticities.keys }
  validates :category, presence: true
  validates :product_type, presence: true
  validates :name, presence: true
  validates :description, length: { maximum: 10_000 }
end
