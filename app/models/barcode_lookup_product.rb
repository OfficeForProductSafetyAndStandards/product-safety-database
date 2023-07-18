class BarcodeLookupProduct < ApplicationRecord
  # serialize :barcode_formats, JSON
  # serialize :images, JSON

  def self.from_api_response(api_response)
    attributes = api_response.slice(
      "barcode_number", "barcode_formats", "mpn", "model", "asin", "title",
      "category", "manufacturer", "brand", "contributors", "age_group",
      "ingredients", "nutrition_facts", "energy_efficiency_class", "color",
      "gender", "material", "pattern", "format", "multipack", "size", "length",
      "width", "height", "weight", "release_date", "description", "images", "last_update"
    )

    create!(attributes) do |product|
      product.raw_api_data = api_response
    end
  end
end
