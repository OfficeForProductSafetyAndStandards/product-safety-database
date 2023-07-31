class BusinessExport < ApplicationRecord
  include CountriesHelper
  include SearchHelper

  # Helps to manage the database query execution time within the PaaS imposed limits
  FIND_IN_BATCH_SIZE = 1000

  belongs_to :user
  has_one_attached :export_file

  def params
    self[:params].deep_symbolize_keys
  end

  def export!
    Axlsx::Package.new do |p|
      book = p.workbook

      add_businesses_worksheet(business_ids, book)

      Tempfile.create("business_export", Rails.root.join("tmp")) do |file|
        p.serialize(file)
        export_file.attach(io: file, filename: "business_export.xlsx")
      end
    end
  end

private

  def business_ids
    return @business_ids if @business_ids

    @search = SearchParams.new(params)
    query = search_query(user)
    @business_ids = Business.search_in_batches(query).map(&:id)
  end

  def add_businesses_worksheet(business_ids, book)
    book.add_worksheet name: "Businesses" do |sheet|
      sheet.add_row(headings_for_business_info_sheet)

      business_ids.each_slice(FIND_IN_BATCH_SIZE) do |batch_business_ids|
        Business
          .includes(:investigations, :locations, :contacts)
          .find(batch_business_ids).each do |business|
          sheet.add_row attributes_business_info_sheet(business), types: :text
        end
      end
    end
  end

  def headings_for_business_info_sheet
    %w[ID
       trading_name
       legal_name
       company_number
       types
       primary_contact_email
       primary_contact_job_title
       primary_contact_phone_number
       primary_location_address_line_1
       primary_location_address_line_2
       primary_location_city
       primary_location_country
       primary_location_county
       primary_location_phone_number
       primary_location_postal_code
       created_at
       updated_at]
  end

  def attributes_business_info_sheet(business)
    investigation_business = business.investigation_businesses.first

    [
      business.id,
      business.trading_name,
      business.legal_name,
      business.company_number,
      investigation_business&.relationship,
      business.primary_contact&.email,
      business.primary_contact&.job_title,
      business.primary_contact&.phone_number,
      business.primary_location&.address_line_1,
      business.primary_location&.address_line_2,
      business.primary_location&.city,
      business.primary_location&.country,
      business.primary_location&.county,
      business.primary_location&.phone_number,
      business.primary_location&.postal_code,
      business.created_at,
      business.updated_at
    ]
  end
end
