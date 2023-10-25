class BulkProductsUploadProductsFileForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  WORKSHEET_HEADERS = [
    "Entry number",
    "Product category",
    "Product Subcategory",
    "Customs code",
    "Country of origin",
    "Barcode number",
    "Product name (including Model and Model Number)",
    "Product description",
    "How many units affected",
    "Manufacturers brand name",
    "Batch number",
    "Is the product Counterfeit",
    "Does the Product have any markings",
    "Was the product placed on the market before 1 january 2021"
  ].freeze

  attribute :random_uuid
  attribute :products_file
  attribute :existing_products_file_id

  validates :products_file, presence: true
  validate :file_type_validation
  validate :file_size_validation
  validate :file_worksheet_validation
  validate :file_header_validation
  validate :file_products_validation

  attr_reader :products, :product_error_messages

  def self.from(bulk_products_upload)
    if bulk_products_upload.products_file.attached?
      new(existing_products_file_id: bulk_products_upload.products_file.signed_id)
    else
      new
    end
  end

  def cache_file!
    return if products_file.blank?

    self.products_file = ActiveStorage::Blob.create_and_upload!(
      io: products_file,
      filename: products_file.original_filename,
      content_type: products_file.content_type
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

    errors.add(:products_file, :wrong_type) if file_not_an_excel_workbook?
  end

  def file_size_validation
    return if file_not_an_excel_workbook?

    errors.add(:products_file, :too_large) if file_too_large?
    errors.add(:products_file, :too_small) if file_too_small?
  end

  def file_worksheet_validation
    return if file_too_large? || file_too_small?

    errors.add(:products_file, :missing_worksheet) if worksheet.blank?
  end

  def file_header_validation
    return if worksheet.blank?

    errors.add(:products_file, :wrong_headers) if headers_mismatched?
  end

  def file_products_validation
    return if headers_mismatched?

    @products, @product_error_messages = validate_products

    if products.empty?
      errors.add(:products_file, :no_products)
    elsif @product_error_messages.present?
      errors.add(:products_file, :malformed_products)
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

    @workbook ||= RubyXL::Parser.parse(ActiveStorage::Blob.service.path_for(products_file.key))

    @workbook["Non compliance Form"]
  end

  def worksheet_headers
    # First row is a title, second row contains the column headers
    worksheet[1].cells.map { |cell| cell&.value&.strip }.compact
  end

  def validate_products
    products = []
    error_messages = {}

    worksheet[2..].each do |row|
      ary = row.cells.map { |cell| cell&.value&.to_s }

      # Ignore completely empty rows or rows with just an entry number
      next if ary.drop(1).compact.empty?

      entry_number, category, subcategory, customs_code, country_of_origin, barcode, name, description, units_affected, brand, batch_number, counterfeit, markings, marketed_before_brexit, *_extra_cells = ary
      authenticity = counterfeit == "Yes" ? "counterfeit" : "genuine"
      has_markings = markings.blank? ? "markings_no" : ({ "No" => "markings_no", "Unknown" => "markings_unknown" }[markings] || "markings_yes")
      markings = has_markings == "markings_yes" ? markings.split(", ") : nil
      when_placed_on_market = marketed_before_brexit == "Yes" ? "before_2021" : "on_or_after_2021"
      product = ProductForm.new(category:, subcategory:, country_of_origin:, barcode:, name:, description:, brand:, authenticity:, has_markings:, markings:, when_placed_on_market:)
      products << { product_data: product.serializable_hash, investigation_data: { customs_code:, units_affected:, batch_number: }, barcode: }
      error_messages[entry_number] = product.errors if product.invalid?
    end

    [products, error_messages]
  end
end
