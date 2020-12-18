require "rails_helper"

RSpec.describe Test::Result, :with_stubbed_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_antivirus do
  describe "validations" do
    context "when missing an investigation" do
      let(:test_result) { build(:test_result, investigation: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:investigation]).to include("must exist")
      end
    end

    context "when missing a product" do
      let(:test_result) { build(:test_result, product: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:product]).to include("Select the product which was tested")
      end
    end
  end
end
