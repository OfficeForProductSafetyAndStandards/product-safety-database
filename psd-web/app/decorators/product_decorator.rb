class ProductDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations

  def summary_list
    rows = [
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Product type" }, value: { text: product_type } },
      { key: { text: "Barcode or serial number" }, value: { text: product_code } },
      include_batch_number ? { key: { text: "Batch number" }, value: { text: batch_number } } : nil,
      { key: { text: "Webpage" }, value: { text: object.webpage } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(country_of_origin) } },
      { key: { text: "Description" }, value: { text: description } }
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows
  end

  def description
    h.simple_format(object.description)
  end

  def combined_categories
    # Combines product type and product category
    # These *should* exist for all products but might not in the future.
    # "Ballpoint pen (stationery)" (if both exist)
    # "Ballpoint pen" (if just product type exists)
    # "Stationery" (if just category exists)
    # nil if neither exists
    if product_type.present? && category.present?
      product_type + " (" + category.downcase + ")"
    elsif product_type.present?
      product_type
    elsif category.present?
      category
    else
      nil
    end
  end

end
