class Investigation < ApplicationRecord
  class AllegationDecorator < ApplicationDecorator

    def title
      title = build_title_from_products || ""
      title << " – #{object.hazard_type}" if object.hazard_type.present?
      title << " (no product specified)" if object.products.empty?
      title.presence || "Untitled case"
    end

    private

    def build_title_from_products
      return object.product_category.dup if object.products.empty?

      title_components = []
      title_components << "#{object.products.length} Products" if object.products.length > 1
      title_components << get_product_property_value_if_shared(:name)
      title_components << get_product_property_value_if_shared(:product_type)
      title_components.reject(&:blank?).join(", ")
    end

    def get_product_property_value_if_shared(property_name)
      first_product = object.products.first
      first_product[property_name] if object.products.drop(1).all? { |product| product[property_name] == first_product[property_name] }
    end

  end
end
