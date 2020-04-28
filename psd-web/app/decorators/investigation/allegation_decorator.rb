class Investigation < ApplicationRecord
  require_dependency "investigation"
  class AllegationDecorator < InvestigationDecorator
    def title
      title = build_title_from_products || "Allegation"
      title << " – #{object.hazard_type.downcase} hazard" if object.hazard_type.present?
      title << compliance_line                            if reported_reason&.safe_and_compliant?
      title << " (no product specified)"                  if object.products.empty?
      title.presence || "Untitled case"
    end

    def display_product_summary_list?
      true
    end

  private

    def compliance_line
      " – #{'product'.pluralize(products.size)} safe and compliant"
    end

    def build_title_from_products
      return object.product_category.dup if object.products.empty?

      title_components = []
      title_components << "#{object.products.length} products" if object.products.length > 1
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
