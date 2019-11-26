class ProductDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations
  def summary_list(include_batch_number: false)
    rows = [
      { key: { text: "Product name" }, value: { text: product.name } },
      { key: { text: "Barcode / serial number" }, value: { text: product.product_code } },
      { key: { text: "Type" }, value: { text: product.product_type } },
      include_batch_number ? { key: { text: "Batch number" }, value: { text: product.batch_number } } : nil,
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Webpage" }, value: { text: product.webpage } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(product.country_of_origin) } },
      { key: { text: "Description" }, value: { text: product.description } }
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows
  end

  def description
    h.simple_format(object.description)
  end

end
