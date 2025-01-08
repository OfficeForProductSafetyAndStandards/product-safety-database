require "rails_helper"

RSpec.describe Test::Result, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  describe "validations" do
    context "when missing an investigation" do
      let(:test_result) { build(:test_result, investigation: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:investigation]).to include("must exist")
      end
    end

    context "when missing an investigation_product" do
      let(:test_result) { build(:test_result, investigation_product: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:investigation_product]).to include("Select the product which was tested")
      end
    end
  end
end
