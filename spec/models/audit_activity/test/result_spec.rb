require "rails_helper"

RSpec.describe AuditActivity::Test::Result, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) { described_class.new(metadata: metadata) }

  let(:test_result) { create(:test_result) }
  let(:metadata) { described_class.build_metadata(test_result) }

  describe "#test_result" do
    it "returns the test result" do
      expect(activity.test_result).to eq test_result
    end
  end

  describe "#title" do
    it "returns a string" do
      expect(activity.title).to match(/\A(Passed test|Failed test|Test result): #{test_result.product.name}\z/)
    end
  end

  describe "#attached_file" do
    it "returns the file" do
      expect(activity.attached_file).to eq test_result.document.blob
    end
  end

  describe "#attached_file_name" do
    it "returns the file name" do
      expect(activity.attached_file_name).to eq test_result.document.blob.filename.to_s
    end
  end

  describe "#legislation" do
    it "returns the test result legislation" do
      expect(activity.legislation).to eq test_result.legislation
    end
  end

  describe "#standards_product_was_tested_against" do
    it "returns the test result standards_product_was_tested_against" do
      expect(activity.standards_product_was_tested_against).to eq test_result.standards_product_was_tested_against
    end
  end

  describe "#result" do
    it "returns the test result" do
      expect(activity.result).to eq test_result.result
    end
  end

  describe "#date" do
    it "returns the test result date" do
      expect(activity.date).to eq test_result.date
    end
  end
end
