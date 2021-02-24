class ProductsDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def to_csv
    CSV.generate do |csv|
      csv << Product.attribute_names.dup.append(additional_csv_fields).flatten
      each { |product| csv << product.to_csv }
    end
  end

private

  def additional_csv_fields
    %w[case_ids]
  end
end
