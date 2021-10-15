require "rails_helper"

RSpec.describe BusinessExport, :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation: organisation) }
  let(:user) { create(:user, :activated, organisation: organisation, team: team, has_viewed_introduction: true) }
  let!(:business) { create(:business) }
  let!(:business_2) { create(:business) }
  let!(:investigation_business) { create(:investigation_business, business: business, investigation: investigation) }
  let!(:investigation) { create(:allegation) }
  let(:business_export) { described_class.create! }

  describe "#export" do
    before do
      create(:location, business: business)
      create(:contact, business: business)

      business_export.export(Business.all.pluck(:id))
    end

    let!(:exported_data) { business_export.export_file.open { |file| Roo::Excelx.new(file) } }

    it "exports one Cases sheet" do
      expect(exported_data.sheets).to eq %w[Businesses]
    end

    # rubocop:disable RSpec/MultipleExpectations

    context "with Cases sheet" do
      let!(:sheet) { exported_data.sheet("Businesses") }

      it "exports ID" do
        expect(sheet.cell(1, 1)).to eq "ID"
        expect(sheet.cell(2, 1)).to eq business.id.to_s
        expect(sheet.cell(3, 1)).to eq business_2.id.to_s
      end

      it "exports trading_name" do
        expect(sheet.cell(1, 2)).to eq "trading_name"
        expect(sheet.cell(2, 2)).to eq business.trading_name
        expect(sheet.cell(3, 2)).to eq business_2.trading_name
      end

      it "exports legal_name" do
        expect(sheet.cell(1, 3)).to eq "legal_name"
        expect(sheet.cell(2, 3)).to eq business.legal_name
        expect(sheet.cell(3, 3)).to eq business_2.legal_name
      end

      it "exports company_number" do
        expect(sheet.cell(1, 4)).to eq "company_number"
        expect(sheet.cell(2, 4)).to eq business.company_number
        expect(sheet.cell(3, 4)).to eq business_2.company_number
      end

      it "exports type" do
        expect(sheet.cell(1, 5)).to eq "types"
        expect(sheet.cell(2, 5)).to eq investigation_business.relationship
        expect(sheet.cell(3, 5)).to eq nil
      end

      it "exports primary_contact_email" do
        expect(sheet.cell(1, 6)).to eq "primary_contact_email"
        expect(sheet.cell(2, 6)).to eq business.primary_contact.try(:email)
        expect(sheet.cell(3, 6)).to eq business_2.primary_contact.try(:email)
      end

      it "exports primary_contact_job_title" do
        expect(sheet.cell(1, 7)).to eq "primary_contact_job_title"
        expect(sheet.cell(2, 7)).to eq business.primary_contact.try(:job_title)
        expect(sheet.cell(3, 7)).to eq business_2.primary_contact.try(:job_title)
      end

      it "exports primary_contact_phone_number" do
        expect(sheet.cell(1, 8)).to eq "primary_contact_phone_number"
        expect(sheet.cell(2, 8)).to eq business.primary_contact.try(:phone_number)
        expect(sheet.cell(3, 8)).to eq business_2.primary_contact.try(:phone_number)
      end
    end

    # rubocop:enable RSpec/MultipleExpectations
  end
end
