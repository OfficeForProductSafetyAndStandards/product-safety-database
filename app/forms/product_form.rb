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
  attribute :affected_units_status
  attribute :number_of_affected_units
  attribute :approx_units
  attribute :exact_units

  before_validation { trim_line_endings(:description) }
  before_validation { convert_gtin_to_13_digits(:gtin13) }
  before_validation { trim_whitespace(:brand) }
  before_validation { nilify_blanks(:gtin13, :brand) }

  validates :gtin13, allow_nil: true, length: { is: 13 }, gtin: true
  validates :authenticity, inclusion: { in: Product.authenticities.keys }
  validates :category, presence: true
  validates :subcategory, presence: true
  validates :name, presence: true
  validates :affected_units_status, inclusion: { in: Product.affected_units_statuses.keys }
  validates :approx_units, presence: true, if: -> { affected_units_status == "approx" }
  validates :exact_units, presence: true, if: -> { affected_units_status == "exact" }
  validates :description, length: { maximum: 10_000 }

  def self.from(product)
    new(product.serializable_hash(except: %i[updated_at]))
  end

  def authenticity_not_provided?
    return false if id.nil?

    authenticity.nil?
  end

  def approx_units
    if attributes["id"]
      number_of_affected_units if affected_units_status == "approx"
    else
      attributes["approx_units"]
    end
  end

  def exact_units
    if attributes["id"]
      number_of_affected_units if affected_units_status == "exact"
    else
      attributes["exact_units"]
    end
  end
end
