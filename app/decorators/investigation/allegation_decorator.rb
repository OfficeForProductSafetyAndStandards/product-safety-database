class Investigation < ApplicationRecord
  require_dependency "investigation"
  class AllegationDecorator < InvestigationDecorator
    def title
      return user_title if user_title

      title = build_title_from_products || "Allegation"
      title << " – #{object.hazard_type.downcase} hazard" if object.hazard_type.present?
      title << compliance_line                            if reported_reason&.safe_and_compliant?
      title << " (no product specified)"                  if display_no_product_specified?
      title.presence || "Untitled notification"
    end

    def display_product_summary_list?
      true
    end

  private

    def compliance_line
      return " - safe and compliant" if products.empty?

      " – #{'product'.pluralize(products.size)} safe and compliant"
    end

    def build_title_from_products
      return object.product_category.dup if object.products.empty?

      title_components = []
      title_components << "#{object.products.length} products" if object.products.length > 1
      title_components << get_product_property_value_if_shared(:name)
      title_components << get_product_property_value_if_shared(:subcategory)
      title_components.reject(&:blank?).join(", ")
    end

    def get_product_property_value_if_shared(property_name)
      first_product = object.products.first
      first_product[property_name] if object.products.drop(1).all? { |product| product[property_name] == first_product[property_name] }
    end

    def display_no_product_specified?
      !reported_reason&.safe_and_compliant? && object.products.empty?
    end
  end
end
