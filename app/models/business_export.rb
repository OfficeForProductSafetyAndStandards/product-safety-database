class BusinessExport < ApplicationRecord
  include CountriesHelper

  # Helps to manage the database query execution time within the PaaS imposed limits
  FIND_IN_BATCH_SIZE = 1000

  has_one_attached :export_file

  def export(business_ids)
    Axlsx::Package.new do |p|
      book = p.workbook

      add_cases_worksheet(book, case_ids, product_counts, business_counts, activity_counts,
                          correspondence_counts, corrective_action_counts, test_counts,
                          risk_assessment_counts)

      Tempfile.create("business_export", Rails.root.join("tmp")) do |file|
        p.serialize(file)
        export_file.attach(io: file, filename: "business_export.xlsx")
      end
    end
  end

private

  def add_businesses_worksheet(business_ids)
    book.add_worksheet name: "Businesses" do |sheet_investigations|
      company_number	created_at	id	legal_name	primary_contact_email	primary_contact_job_title	primary_contact_job_title	primary_contact_phone_number	primary_location_address_line_1	primary_location_address_line_2	primary_location_city	primary_location_country	primary_location_county	primary_location_phone_number	primary_location_postal_code	trading_name	types	updated_at
      sheet_investigations.add_row %w[ID
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

      businesses.each_slice(FIND_IN_BATCH_SIZE) do |batch_business_ids|
        Business
          .includes(:investigations, :locations, :contacts)
          .includes(:complainant, :products, :owner_team, :owner_user, { creator_user: :team })
          .find(batch_business_ids).each do |business|
          sheet_investigations.add_row [
            business.id,
            business.trading_name,
            business.legal_name,
            business.company_number,
            business.investigation_businesses.map(&:relationship),
            business.primary_contact.email,
            business.primary_contact.job_title,
            business.primary_contact.phone_number,
            business.primary_location.address_line_1,
            business.primary_location.address_line_2,
            business.primary_location.city,
            business.primary_location.country,
            business.primary_location.county,
            business.primary_location.phone_number,
            business.primary_location.postal_code,
            business.created_at,
            business.updated_at
          ], types: :text
        end
      end
    end
  end
end
