class BarcodeLookupService
  def self.lookup(barcode)
    existing_product = Product.find_by(barcode:)
    return existing_product if existing_product.present?

    existing_lookup_product = BarcodeLookupProduct.find_by(barcode_number: barcode)
    return existing_lookup_product if existing_lookup_product.present?

    api_key = ENV["BARCODE_LOOKUP_API_KEY"]
    url = "https://api.barcodelookup.com/v3/products?barcode=#{barcode}&formatted=y&key=#{api_key}"

    uri = URI(url)
    response = Net::HTTP.get(uri)
    parsed_response = JSON.parse(response)

    if parsed_response["products"].present?
      product_data = parsed_response["products"].first
      extract_product_data(product_data)
    else
      {}
    end
  end

  def self.extract_product_data(product_data)
    attributes = product_data.slice(
      "barcode_number", "barcode_formats", "mpn", "model", "asin", "title",
      "category", "manufacturer", "brand", "contributors", "age_group",
      "ingredients", "nutrition_facts", "energy_efficiency_class", "color",
      "gender", "material", "pattern", "format", "multipack", "size", "length",
      "width", "height", "weight", "release_date", "description", "images"
    )
    BarcodeLookupProduct.create_from_api_response(attributes)
  end
end
