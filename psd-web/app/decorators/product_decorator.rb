class ProductDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations

  def summary_list(include_batch_number: false)
    rows = [
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "Barcode / serial number" }, value: { text: product_code } },
      { key: { text: "Type" }, value: { text: product_type } },
      include_batch_number ? { key: { text: "Batch number" }, value: { text: batch_number } } : nil,
      { key: { text: "Category" }, value: { text: category } },
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
end
