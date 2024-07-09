require "rails_helper"

RSpec.describe BusinessExport, :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let!(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let!(:business) { create(:business).decorate }
  let!(:business_2) { create(:business).decorate }
  let!(:investigation_business) { create(:investigation_business, business:, investigation:).decorate }
  let!(:investigation) { create(:allegation).decorate }
  let(:params) { {} }
  let(:business_export) { described_class.create!(user:, params:) }

  describe "#export!" do
    before do
      create(:location, business:)
      create(:contact, business:)

      business_export.export!
    end

    let!(:exported_data) { business_export.export_file.open { |file| Roo::Excelx.new(file) } }
    let!(:sheet) { exported_data.sheet("Businesses") }

    # rubocop:disable RSpec/MultipleExpectations
    # rubocop:disable RSpec/ExampleLength
    it "exports business data" do
      expect(sheet.cell(1, 1)).to eq "ID"
      expect(sheet.cell(2, 1)).to eq business.id.to_s
      expect(sheet.cell(3, 1)).to eq business_2.id.to_s

      expect(sheet.cell(1, 2)).to eq "trading_name"
      expect(sheet.cell(2, 2)).to eq business.trading_name
      expect(sheet.cell(3, 2)).to eq business_2.trading_name

      expect(sheet.cell(1, 3)).to eq "legal_name"
      expect(sheet.cell(2, 3)).to eq business.legal_name
      expect(sheet.cell(3, 3)).to eq business_2.legal_name

      expect(sheet.cell(1, 4)).to eq "company_number"
      expect(sheet.cell(2, 4)).to eq business.company_number
      expect(sheet.cell(3, 4)).to eq business_2.company_number

      expect(sheet.cell(1, 5)).to eq "types"
      expect(sheet.cell(2, 5)).to eq investigation_business.relationship
      expect(sheet.cell(3, 5)).to be_nil

      expect(sheet.cell(1, 6)).to eq "primary_contact_email"
      expect(sheet.cell(2, 6)).to eq business.primary_contact.try(:email)
      expect(sheet.cell(3, 6)).to eq business_2.primary_contact.try(:email)

      expect(sheet.cell(1, 7)).to eq "primary_contact_job_title"
      expect(sheet.cell(2, 7)).to eq business.primary_contact.try(:job_title)
      expect(sheet.cell(3, 7)).to eq business_2.primary_contact.try(:job_title)

      expect(sheet.cell(1, 8)).to eq "primary_contact_phone_number"
      expect(sheet.cell(2, 8)).to eq business.primary_contact.try(:phone_number)
      expect(sheet.cell(3, 8)).to eq business_2.primary_contact.try(:phone_number)

      expect(sheet.cell(1, 9)).to eq "primary_location_address_line_1"
      expect(sheet.cell(2, 9)).to eq business.primary_location.try(:address_line_1)
      expect(sheet.cell(3, 9)).to eq business_2.primary_location.try(:address_line_1)

      expect(sheet.cell(1, 10)).to eq "primary_location_address_line_2"
      expect(sheet.cell(2, 10)).to eq business.primary_location.try(:address_line_2)
      expect(sheet.cell(3, 10)).to eq business_2.primary_location.try(:address_line_2)

      expect(sheet.cell(1, 11)).to eq "primary_location_city"
      expect(sheet.cell(2, 11)).to eq business.primary_location.try(:city)
      expect(sheet.cell(3, 11)).to eq business_2.primary_location.try(:city)

      expect(sheet.cell(1, 12)).to eq "primary_location_country"
      expect(sheet.cell(2, 12)).to eq business.primary_location.try(:country)
      expect(sheet.cell(3, 12)).to eq business_2.primary_location.try(:country)

      expect(sheet.cell(1, 13)).to eq "primary_location_county"
      expect(sheet.cell(2, 13)).to eq business.primary_location.try(:county)
      expect(sheet.cell(3, 13)).to eq business_2.primary_location.try(:county)

      expect(sheet.cell(1, 14)).to eq "primary_location_phone_number"
      expect(sheet.cell(2, 14)).to eq business.primary_location.try(:phone_number)
      expect(sheet.cell(3, 14)).to eq business_2.primary_location.try(:phone_number)

      expect(sheet.cell(1, 15)).to eq "primary_location_postal_code"
      expect(sheet.cell(2, 15)).to eq business.primary_location.try(:postal_code)
      expect(sheet.cell(3, 15)).to eq business_2.primary_location.try(:postal_code)

      expect(sheet.cell(1, 18)).to eq "case_id"
      expect(sheet.cell(2, 18)).to eq investigation.pretty_id
      expect(sheet.cell(3, 18)).to be_nil
    end
    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength
  end
end
