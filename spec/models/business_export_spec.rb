require "rails_helper"

RSpec.describe BusinessExport, :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:params) { {} }
  let(:business_export) { described_class.create!(user:, params:) }
  let(:exported_data) { business_export.export_file.open { |file| Roo::Excelx.new(file) } }
  let(:sheet) { exported_data.sheet("Businesses") }

  describe "#export!" do
    context "when exporting regular business data" do
      let!(:business) { create(:business).decorate }
      let!(:business_two) { create(:business).decorate }
      let!(:investigation) { create(:allegation).decorate }
      let!(:investigation_business) { create(:investigation_business, business:, investigation:).decorate }

      before do
        create(:location, business:)
        create(:contact, business:)
        business_export.export!
      end

      it "includes headers in the first row" do
        expect(sheet.row(1)[0..18]).to eq %w[ID trading_name legal_name company_number types primary_contact_email primary_contact_job_title primary_contact_phone_number primary_location_address_line_1 primary_location_address_line_2 primary_location_city primary_location_country primary_location_county primary_location_phone_number primary_location_postal_code created_at updated_at case_id]
      end

      it "exports business with investigation data" do
        expect(sheet.row(2)[0..18]).to eq [business.id.to_s, business.trading_name, business.legal_name, business.company_number, investigation_business.relationship, business.primary_contact.try(:email), business.primary_contact.try(:job_title), business.primary_contact.try(:phone_number), business.primary_location.try(:address_line_1), business.primary_location.try(:address_line_2), business.primary_location.try(:city), business.primary_location.try(:country), business.primary_location.try(:county), business.primary_location.try(:phone_number), business.primary_location.try(:postal_code), business.created_at.to_formatted_s(:xmlschema), business.updated_at.to_formatted_s(:xmlschema), investigation.pretty_id]
      end

      it "exports business without investigation data" do
        expect(sheet.row(3)[0..18]).to eq [business_two.id.to_s, business_two.trading_name, business_two.legal_name, business_two.company_number, nil, business_two.primary_contact.try(:email), business_two.primary_contact.try(:job_title), business_two.primary_contact.try(:phone_number), business_two.primary_location.try(:address_line_1), business_two.primary_location.try(:address_line_2), business_two.primary_location.try(:city), business_two.primary_location.try(:country), business_two.primary_location.try(:county), business_two.primary_location.try(:phone_number), business_two.primary_location.try(:postal_code), business_two.created_at.to_formatted_s(:xmlschema), business_two.updated_at.to_formatted_s(:xmlschema), nil]
      end
    end

    context "when business has draft notifications" do
      let!(:business_with_draft_notification) { create(:business) }
      let!(:draft_notification) do
        create(:notification, user_title: "Draft notification title").tap do |notification|
          notification.update_column(:state, "draft")
        end
      end
      let!(:investigation_business_draft) do
        create(:investigation_business,
               business: business_with_draft_notification,
               investigation: draft_notification)
      end

      before do
        business_export.export!
      end

      it "has correct relationship" do
        expect(investigation_business_draft.investigation_id).to eq draft_notification.id
        expect(investigation_business_draft.business_id).to eq business_with_draft_notification.id
      end

      it "excludes draft notification data from export" do
        business_row = sheet.row(2)[0..18]
        expect(business_row).to eq [business_with_draft_notification.id.to_s, business_with_draft_notification.trading_name, business_with_draft_notification.legal_name, business_with_draft_notification.company_number, nil, business_with_draft_notification.primary_contact.try(:email), business_with_draft_notification.primary_contact.try(:job_title), business_with_draft_notification.primary_contact.try(:phone_number), business_with_draft_notification.primary_location.try(:address_line_1), business_with_draft_notification.primary_location.try(:address_line_2), business_with_draft_notification.primary_location.try(:city), business_with_draft_notification.primary_location.try(:country), business_with_draft_notification.primary_location.try(:county), business_with_draft_notification.primary_location.try(:phone_number), business_with_draft_notification.primary_location.try(:postal_code), business_with_draft_notification.created_at.to_formatted_s(:xmlschema), business_with_draft_notification.updated_at.to_formatted_s(:xmlschema), nil]
      end
    end
  end
end
