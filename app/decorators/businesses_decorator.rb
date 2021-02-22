class BusinessesDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def to_csv
    CSV.generate do |csv|
      csv << Business.attributes_for_export
      each { |business| csv << business.to_csv }
    end
  end
end
