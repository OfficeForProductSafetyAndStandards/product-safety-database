class BusinessExport < ApplicationRecord
  include CountriesHelper
  include BusinessesHelper

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
    @business_ids = search_for_businesses_in_batches(user).map(&:id)
  end

  def add_businesses_worksheet(business_ids, book)
    book.add_worksheet name: "Businesses" do |sheet|
      sheet.add_row %w[ID
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

      business_ids.each_slice(FIND_IN_BATCH_SIZE) do |batch_business_ids|
        Business
          .includes(:investigations, :locations, :contacts)
          .find(batch_business_ids).each do |business|
          sheet.add_row [
            business.id,
            business.trading_name,
            business.legal_name,
            business.company_number,
            business.investigation_businesses.first.try(:relationship),
            business.primary_contact.try(:email),
            business.primary_contact.try(:job_title),
            business.primary_contact.try(:phone_number),
            business.primary_location.try(:address_line_1),
            business.primary_location.try(:address_line_2),
            business.primary_location.try(:city),
            business.primary_location.try(:country),
            business.primary_location.try(:county),
            business.primary_location.try(:phone_number),
            business.primary_location.try(:postal_code),
            business.created_at,
            business.updated_at
          ], types: :text
        end
      end
    end
  end
end
