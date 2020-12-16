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
  attribute :has_markings, :boolean
  attribute :markings

  attr_accessor :approx_units
  attr_accessor :exact_units

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

  validates :has_markings, inclusion: { in: [true, false] }
  validate :markings_validity, if: -> { has_markings }

  def self.from(product)
    new(product.serializable_hash(except: %i[updated_at])).tap do |product_form|
      if product.affected_units_status == Product.affected_units_statuses["approx"]
        product_form.approx_units = product.number_of_affected_units
      elsif product.affected_units_status == Product.affected_units_statuses["exact"]
        product_form.exact_units = product.number_of_affected_units
      end

      product_form.has_markings = product.markings.present?
    end
  end

  def number_of_affected_units
    return if affected_units_status.blank?

    if affected_units_status.inquiry.exact?
      exact_units
    elsif affected_units_status.inquiry.approx?
      approx_units
    end
  end

  def authenticity_not_provided?
    return false if id.nil?

    authenticity.nil?
  end

  def markings=(value)
    super(value ? value.uniq : nil)
  end

  def markings
    has_markings ? super : []
  end

private

  def markings_validity
    if markings.blank? || !markings.all? { |value| Product::MARKINGS.include?(value) }
      errors.add(:markings, :invalid)
    end
  end
end
