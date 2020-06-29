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

    context "when missing a test date" do
      let(:test_result) { build(:test_result, date: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:date]).to include("Enter date of the test")
      end
    end

    context "when details are too long" do
      let(:test_result) { build(:test_result, details: ("a" * 50_001)) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:details]).to include("Details is too long (maximum is 50000 characters)")
      end
    end

    context "when rest result is missing" do
      let(:test_result) { build(:test_result, result: nil) }

      it "is invalid and includes an error message", :aggregate_failures do
        expect(test_result).not_to be_valid
        expect(test_result.errors.messages[:result]).to include("Select result of the test")
      end
    end
  end

  describe "saving" do
    let!(:product) { create(:product) }
    let!(:investigation) { create(:allegation) }
    let(:test_result) { build(:test_result, investigation: investigation, product: product) }

    it "creates an activity entry" do
      expect { test_result.save! }.to change(Activity, :count).by(1)
    end
  end
end
