require "rails_helper"

RSpec.describe Test::ResultDecorator, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { test_result.decorate }

let(:test_result) { build(:test_result) }

  describe "#title" do
    context "when the test result has passed" do
      before { test_result.result = "passed" }

      it "returns 'Passed test: <product name>'" do
        expect(decorated_corrective_action.title).to eq("Passed test: #{test_result.investigation_product.name}")
      end
    end

    context "when the test result has failed" do
      before { test_result.result = "failed" }

      it "returns 'Failed test: <product name>'" do
        expect(decorated_corrective_action.title).to eq("Failed test: #{test_result.investigation_product.name}")
      end
    end

    context "when the test result has not passed or failed" do
      before { test_result.result = "other" }

      it "returns 'Test result: <product name>'" do
        expect(decorated_corrective_action.title).to eq("Test result: #{test_result.investigation_product.name}")
      end
    end
  end

  describe "#case_id" do
    it "returns the investigation pretty id" do
      expect(decorated_corrective_action.case_id).to eq(test_result.investigation.pretty_id)
    end
  end
end