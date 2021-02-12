class ProductsDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def to_csv
    CSV.generate do |csv|
      csv << Product.attribute_names
      each { |product| csv << product.to_csv }
    end
  end
end
