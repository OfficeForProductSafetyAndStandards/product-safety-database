class ProductsDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def to_csv
    CSV.generate do |csv|
      csv << attributes_for_export
      each { |product| csv << product_to_csv(product) }
    end
  end

private

  def product_to_csv(product)
    attributes_for_export.map { |key| product.send(key) }
  end

  def attributes_for_export
    Product.attribute_names.dup.concat(%w[case_ids]).sort
  end
end
