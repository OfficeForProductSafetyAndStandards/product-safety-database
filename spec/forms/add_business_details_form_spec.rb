require "rails_helper"

RSpec.describe AddBusinessDetailsForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(add_business_details_form_params) }

  let(:add_business_details_form_params) do
    {
      legal_name:,
      trading_name:,
    }
  end
  let(:legal_name) { "Legal name" }
  let(:trading_name) { "Trading name" }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no legal name" do
      let(:legal_name) { nil }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no trading name" do
      let(:trading_name) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
