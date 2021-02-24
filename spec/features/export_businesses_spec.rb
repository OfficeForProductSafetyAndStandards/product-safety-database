require "rails_helper"

RSpec.feature "Exporting businesses", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :psd_admin, has_viewed_introduction: true) }

  # Set up a variety of scenarios; one with a case, one with locations/contacts, one with no cases or locations or contacts
  let!(:investigation) { create(:allegation, :with_business) }
  let(:business_1) { investigation.businesses.first }
  let!(:business_2) { create(:business, trading_name: "ACME Ltd", locations: [location], contacts: [contact]).decorate }
  let!(:business_3) { create(:business, trading_name: "OPSS").decorate }
  let(:location) { build(:location, business: nil) }
  let(:contact) { build(:contact, business: nil) }

  scenario "all businesses" do
    Business.import(force: true)

    sign_in user
    visit "/businesses"

    click_link "Export as spreadsheet"

    expect(page.body).to eq("case_ids,company_number,created_at,id,legal_name,primary_contact_email,primary_contact_job_title,primary_contact_name,primary_contact_phone_number,primary_location_address_line_1,primary_location_address_line_2,primary_location_city,primary_location_country,primary_location_county,primary_location_phone_number,primary_location_postal_code,trading_name,types,updated_at\n[],#{business_3.company_number},#{business_3.created_at},#{business_3.id},#{business_3.legal_name},,,,,,,,,,,,#{business_3.trading_name},[],#{business_3.updated_at}\n[],#{business_2.company_number},#{business_2.created_at},#{business_2.id},#{business_2.legal_name},#{contact.email},#{contact.job_title},#{contact.name},#{contact.phone_number},#{location.address_line_1},#{location.address_line_2},#{location.city},#{location.country},#{location.county},#{location.phone_number},#{location.postal_code},#{business_2.trading_name},[],#{business_2.updated_at}\n\"[\"\"#{investigation.pretty_id}\"\"]\",#{business_1.company_number},#{business_1.created_at},#{business_1.id},#{business_1.legal_name},,,,,,,,,,,,#{business_1.trading_name},\"[\"\"Manufacturer\"\"]\",#{business_1.updated_at}\n")
  end

  scenario "searching businesses" do
    Business.import(force: true)

    sign_in user
    visit "/businesses"

    fill_in "Keywords", with: "OPSS"
    click_button "Search"

    click_link "Export as spreadsheet"

    expect(page.body).to eq("case_ids,company_number,created_at,id,legal_name,primary_contact_email,primary_contact_job_title,primary_contact_name,primary_contact_phone_number,primary_location_address_line_1,primary_location_address_line_2,primary_location_city,primary_location_country,primary_location_county,primary_location_phone_number,primary_location_postal_code,trading_name,types,updated_at\n[],#{business_3.company_number},#{business_3.created_at},#{business_3.id},#{business_3.legal_name},,,,,,,,,,,,#{business_3.trading_name},[],#{business_3.updated_at}\n")
  end
end
