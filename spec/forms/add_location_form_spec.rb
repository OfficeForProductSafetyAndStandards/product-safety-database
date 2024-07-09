require "rails_helper"

RSpec.describe AddLocationForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(add_location_form_params) }

  let(:valid_address_params) do
    {
      address_line_1: "123 Fake St",
      address_line_2: "Fake Heath",
      city: "Faketon",
      county: "Fakeshire",
      postal_code: "FA1 2KE",
      country: "country:BJ",
    }
  end

  let(:add_location_form_params) { valid_address_params }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no country" do
      let(:add_location_form_params) do
        valid_address_params.merge(country: nil)
      end

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
