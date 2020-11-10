class ProductDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations

  def pretty_description
    "Product: #{name}"
  end

  def summary_list
    rows = [
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Product type" }, value: { text: product_type } },
      { key: { text: "Product authenticity" }, value: { text: authenticity } },
      { key: { text: "Product brand" }, value: { text: object.brand } },
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "Barcode number" }, value: { text: gtin13 } },
      { key: { text: "Batch number" }, value: { text: batch_number } },
      { key: { text: "Other product identifiers" }, value: { text: product_code } },
      { key: { text: "Webpage" }, value: { text: object.webpage } },
      { key: { text: "Description" }, value: { text: description } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(country_of_origin) } }
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows
  end

  def authenticity
    I18n.t(object.authenticity || :missing, scope: Product.model_name.i18n_key)
  end

  def description
    h.simple_format(object.description)
  end

  def product_type_and_category_label
    product_and_category = [product_type.presence, category.presence].compact

    if product_and_category.length > 1
      "#{product_and_category.first} (#{product_and_category.last.downcase})"
    else
      product_and_category.first
    end
  end
end
