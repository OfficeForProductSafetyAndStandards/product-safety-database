require "rails_helper"

RSpec.describe AddLocationForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(add_location_form_params) }

  let(:add_location_form_params) do
    {
      address_line_1:,
      address_line_2:,
      city:,
      county:,
      postal_code:,
      country:,
    }
  end
  let(:address_line_1) { "123 Fake St" }
  let(:address_line_2) { "Fake Heath" }
  let(:city) { "Faketon" }
  let(:county) { "Fakeshire" }
  let(:postal_code) { "FA1 2KE" }
  let(:country) { "country:BJ" }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no country" do
      let(:country) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
