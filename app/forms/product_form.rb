class ProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Serialization
  include SanitizationHelper

  attribute :id
  attribute :authenticity
  attribute :batch_number
  attribute :brand
  attribute :category
  attribute :country_of_origin
  attribute :description
  attribute :gtin13
  attribute :name
  attribute :product_code
  attribute :subcategory
  attribute :webpage
  attribute :created_at, :datetime

  before_validation { trim_line_endings(:description) }
  before_validation { convert_gtin_to_13_digits(:gtin13) }
  before_validation { trim_whitespace(:brand) }
  before_validation { nilify_blanks(:gtin13, :brand) }

  validates :gtin13, allow_nil: true, length: { is: 13 }, gtin: true
  validates :authenticity, inclusion: { in: Product.authenticities.keys }
  validates :category, presence: true
  validates :subcategory, presence: true
  validates :name, presence: true
  validates :description, length: { maximum: 10_000 }

  def self.from(product)
    new(product.serializable_hash(except: %i[updated_at]))
  end

  def authenticity_not_provided?
    return false if id.nil?

    authenticity.nil?
  end
end
