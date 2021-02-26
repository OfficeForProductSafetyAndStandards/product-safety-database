class BusinessesDecorator < Draper::CollectionDecorator
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  def to_csv
    CSV.generate do |csv|
      csv << attributes_for_export
      each { |business| csv << export_attribute_values_for_business(business) }
    end
  end

private

  def attributes_for_export
    Business.attribute_names.dup.concat(%w[types case_ids primary_location_address_line_1 primary_location_address_line_2 primary_location_city primary_location_country primary_location_county primary_location_postal_code primary_location_phone_number primary_contact_email primary_contact_name primary_contact_phone_number primary_contact_job_title]).sort.freeze
  end

  def export_attribute_values_for_business(business)
    attributes_for_export.map { |key| business.send(key) }
  end
end
