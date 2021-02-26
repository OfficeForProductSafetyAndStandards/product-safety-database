class BusinessDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations

  # Presentational data used for CSV export
  delegate :address_line_1, :address_line_2, :city, :country, :county, :phone_number, :postal_code, to: :primary_location, prefix: true, allow_nil: true
  delegate :email, :job_title, :name, :phone_number, to: :primary_contact, prefix: true, allow_nil: true

  # Presentational data used for CSV export
  def types
    investigation_businesses.map(&:relationship)
  end

  # Presentational data used for CSV export
  def case_ids
    investigations.map(&:pretty_id)
  end
end
