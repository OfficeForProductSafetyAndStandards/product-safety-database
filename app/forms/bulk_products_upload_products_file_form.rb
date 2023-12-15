class BulkProductsUploadProductsFileForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  WORKSHEET_HEADERS = [
    "Entry number",
    "Product category*",
    "Product subcategory*",
    "Customs code",
    "Country of origin*",
    "Barcode number",
    "Product name (including model and model number)*",
    "Product description",
    "How many units affected?",
    "Manufacturer's brand name",
    "Batch number",
    "Is the product counterfeit?*",
    "Does the product have any markings?*",
    "Was the product placed on the market before 01 January 2021?"
  ].freeze

  attribute :random_uuid
  attribute :products_file
  attribute :products_file_upload
  attribute :existing_products_file_id

  validates :products_file_upload, presence: true, unless: -> { products_file.present? }
  validate :file_type_validation
  validate :file_size_validation
  validate :file_worksheet_validation
  validate :file_header_validation
  validate :file_products_validation

  attr_reader :products, :product_error_messages

  def self.from(bulk_products_upload, params = {})
    if bulk_products_upload.products_file.attached?
      new(existing_products_file_id: bulk_products_upload.products_file.signed_id, **params)
    else
      new(params)
    end
  end

  def cache_file!
    return if products_file_upload.blank?

    self.products_file = ActiveStorage::Blob.create_and_upload!(
      io: products_file_upload,
      filename: products_file_upload.original_filename,
      content_type: products_file_upload.content_type
    )

    self.existing_products_file_id = products_file.signed_id
  end

  def load_products_file
    if existing_products_file_id.present? && products_file.nil?
      self.products_file = ActiveStorage::Blob.find_signed!(existing_products_file_id)
    end
  end

private

  def file_type_validation
    return if products_file.blank?

    errors.add(:products_file_upload, :wrong_type) if file_not_an_excel_workbook?
  end

  def file_size_validation
    return if file_not_an_excel_workbook?

    errors.add(:products_file_upload, :too_large) if file_too_large?
    errors.add(:products_file_upload, :too_small) if file_too_small?
  end

  def file_worksheet_validation
    return if file_too_large? || file_too_small?

    errors.add(:products_file_upload, :missing_worksheet) if worksheet.blank?
  end

  def file_header_validation
    return if worksheet.blank?

    errors.add(:products_file_upload, :wrong_headers) if headers_mismatched?
  end

  def file_products_validation
    return if worksheet.blank? || headers_mismatched?

    @products, @product_error_messages = validate_products

    if products.empty?
      errors.add(:products_file_upload, :no_products)
    elsif @product_error_messages.present?
      errors.add(:products_file_upload, :malformed_products)
    end
  end

  def file_not_an_excel_workbook?
    products_file&.content_type != "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def file_too_large?
    products_file&.byte_size.to_i > 30.megabytes
  end

  def file_too_small?
    products_file&.byte_size.to_i < 1.bytes
  end

  def headers_mismatched?
    worksheet_headers != WORKSHEET_HEADERS
  end

  def worksheet
    return if products_file.blank?

    @workbook ||= products_file.open do |file|
      RubyXL::Parser.parse(file.path)
    end

    @workbook["Non compliance Form"]
  end

  def worksheet_headers
    # First row is a note, second row is a title, third row contains the column headers
    worksheet[2].cells.map { |cell| cell&.value&.to_s&.strip }.compact
  end

  def validate_products
    products = []
    error_messages = {}

    worksheet[3..].each do |row|
      next if row.nil?

      ary = row.cells.map { |cell| cell&.value&.to_s }

      # Ignore completely empty rows or rows with just an entry number
      next if ary.drop(1).compact.empty?

      entry_number, category, subcategory, customs_code, country_of_origin, barcode, name, description, number_of_affected_units, brand, batch_number, counterfeit, markings, marketed_before_brexit, *_extra_cells = ary
      authenticity = counterfeit.blank? ? nil : { "Yes" => "counterfeit", "No" => "genuine", "Unsure" => "unsure" }[counterfeit&.strip]
      has_markings = markings.blank? ? nil : ({ "No" => "markings_no", "Unknown" => "markings_unknown" }[markings&.strip] || "markings_yes")
      markings = has_markings == "markings_yes" ? markings.split(", ") : nil
      when_placed_on_market = marketed_before_brexit.blank? ? nil : { "Yes" => "before_2021", "No" => "on_or_after_2021", "Unable to ascertain" => "unknown_date" }[marketed_before_brexit&.strip]
      product = ProductForm.new(category:, subcategory:, country_of_origin: country_to_code(country_of_origin), barcode:, name:, description:, brand:, authenticity:, has_markings:, markings:, when_placed_on_market:)
      products << { product_data: product.serializable_hash, investigation_data: { customs_code:, number_of_affected_units:, batch_number: }, barcode: }
      error_messages[entry_number] = product.errors if product.invalid?
    end

    [products, error_messages]
  end

  def country_to_code(country)
    code = Country.all.find { |c| c[0] == country }
    (code && code[1]) || country
  end
end
