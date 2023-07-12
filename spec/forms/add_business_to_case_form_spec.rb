require "rails_helper"

RSpec.describe AddBusinessToCaseForm, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(business_form_params.merge(current_user:)) }

  let(:country) { "United Kingdom" }
  let(:business_form_params) do
    {
      legal_name: "Test Business",
      trading_name: "Test Business",
      company_number: "12345678",
      locations_attributes: {
        "0" => {
          name: "Registered office address",
          address_line_1: "1 Test Street",
          city: "Test Town",
          country:
        }
      },
      contacts_attributes: {
        "0" => {
          name: "Test User",
          email: "email@email.email",
        }
      }
    }
  end

  let(:current_user) { create(:user) }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "without a country picked" do
      let(:country) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end

  describe "#business_object" do
    it "returns the Business object" do
      expect(form.business_object).to be_a(Business)
    end

    it "sets the legal_name" do
      expect(form.business_object.legal_name).to eq("Test Business")
    end
  end

  describe "#online_marketplace" do
    before do
      form.online_marketplace_id = online_marketplace.id
    end

    let(:online_marketplace) { create(:online_marketplace) }

    it "returns the OnlineMarketplace object" do
      expect(form.online_marketplace).to eq(online_marketplace)
    end
  end
end
