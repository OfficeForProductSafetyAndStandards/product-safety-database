require "rails_helper"

RSpec.describe AuditActivity::Test::ResultDecorator, :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) do
    AuditActivity::Test::Result.create!(
      investigation: test_result.investigation,
      investigation_product:,
      metadata: described_class.build_metadata(test_result),
      added_by_user: user
    ).decorate
  end

  let(:investigation_product) { test_result.investigation_product }
  let(:test_result) { create(:test_result, result: :passed, standards_product_was_tested_against:) }
  let(:user) { test_result.investigation.creator_user }
  let(:standards_product_was_tested_against) { %w[test1 test2] }

  describe "#title" do
    it "returns a string" do
      expect(activity.title).to match(/\A(Passed test|Failed test|Test result): #{test_result.investigation_product.name}\z/)
    end
  end

  describe "#date" do
    it "returns a formatted string" do
      expect(activity.date).to eq(test_result.date.to_formatted_s(:govuk))
    end
  end

  describe "#result" do
    it "returns a formatted string" do
      expect(activity.result).to eq("Passed")
    end
  end

  describe "#standards_product_was_tested_against" do
    context "when nil" do
      let(:standards_product_was_tested_against) { nil }

      it "returns nil" do
        expect(activity.standards_product_was_tested_against).to be_nil
      end
    end

    context "when not nil" do
      it "returns a String" do
        expect(activity.standards_product_was_tested_against).to eq("test1, test2")
      end
    end
  end
end
