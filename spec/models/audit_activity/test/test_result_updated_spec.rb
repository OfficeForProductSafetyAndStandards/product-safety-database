require "rails_helper"

RSpec.describe AuditActivity::Test::TestResultUpdated, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  let(:product) { create(:product) }
  let(:test_result) do
    create(:test_result,
           product: product,
           investigation: create(:allegation))
  end

  describe "#test_result" do
    let(:activity) { described_class.new(metadata: { test_result_id: test_result.id }) }

    it "returns the test result" do
      expect(activity.test_result).to eq test_result
    end
  end

  describe "#new_date_of_test" do
    let(:activity) { described_class.new(metadata: { updates: { date: %w[2010-01-01 2020-01-01] } }) }

    it "returns the new date as a date object" do
      expect(activity.new_date_of_test).to eq Date.parse("2020-01-01")
    end
  end

  describe "#new_result" do
    let(:activity) { described_class.new(metadata: { updates: { result: %w[Passed Failed] } }) }

    it "returns the new test result" do
      expect(activity.new_result).to eq "Failed"
    end
  end

  describe "#new_details" do
    let(:activity) { described_class.new(metadata: { updates: { details: ["old details", new_details] } }) }
    context "new details is blank" do
      let(:new_details) { ""}

      it "returns `Removed` when new_details is blank" do
        expect(activity.new_details).to eq "Removed"
      end
    end

    context "new_details is not blank" do
      let(:new_details) { "New"}

      it "returns new details when new_details is not blank" do
        expect(activity.new_details).to eq "New"
      end
    end
  end

  describe "#new_file_description" do
    let(:activity) { described_class.new(metadata: { updates: { file_description: ["old description", new_file_description] } }) }
    context "new details is blank" do
      let(:new_file_description) { ""}

      it "returns `Removed` when new_details is blank" do
        expect(activity.new_file_description).to eq "Removed"
      end
    end

    context "new_details is not blank" do
      let(:new_file_description) { "New"}

      it "returns new details when new_details is not blank" do
        expect(activity.new_file_description).to eq "New"
      end
    end
  end

  describe "#new_product" do
    let(:new_product) { create(:product) }
    let(:activity) { described_class.new(metadata: { updates: { product_id: [product.id, new_product.id] } }) }

    it "returns the new product" do
      expect(activity.new_product).to eq new_product
    end
  end
end
