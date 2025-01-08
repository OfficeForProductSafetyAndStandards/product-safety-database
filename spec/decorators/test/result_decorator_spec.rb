require "rails_helper"

RSpec.describe Test::ResultDecorator, :with_stubbed_mailer do
  subject(:decorated_test_result) { test_result.decorate }

  let(:result_type) { "passed" }
  let(:test_result) { build(:test_result, result: result_type) }
  let(:product_name) { test_result.investigation_product.name }

  describe "#title" do
    context "when the test result has passed" do
      let(:result_type) { "passed" }

      it "returns 'Passed test: <product name>'" do
        expect(decorated_test_result.title).to eq("Passed test: #{product_name}")
      end
    end

    context "when the test result has failed" do
      let(:result_type) { "failed" }

      it "returns 'Failed test: <product name>'" do
        expect(decorated_test_result.title).to eq("Failed test: #{product_name}")
      end
    end

    context "when the test result has other status" do
      let(:result_type) { "other" }

      it "returns 'Test result: <product name>'" do
        expect(decorated_test_result.title).to eq("Test result: #{product_name}")
      end
    end
  end

  describe "#case_id" do
    it "returns the investigation pretty id" do
      expect(decorated_test_result.case_id).to eq(test_result.investigation.pretty_id)
    end
  end

  describe "#product_tested" do
    it "returns the correct product description" do
      expect(decorated_test_result.product_tested).to eq("#{product_name} (#{test_result.investigation_product.psd_ref})")
    end
  end

  describe "#attachment_description" do
    context "when document has a blob with description" do
      before do
        blob = instance_double(ActiveStorage::Blob, metadata: { "description" => "Test doc" })
        document = instance_double(ActiveStorage::Attachment, blob:)
        allow(test_result).to receive(:document).and_return(document)
      end

      it "returns the correct description" do
        expect(decorated_test_result.attachment_description).to eq("Test doc")
      end
    end

    context "when document has no blob" do
      before do
        document = instance_double(ActiveStorage::Attachment, blob: nil)
        allow(test_result).to receive(:document).and_return(document)
      end

      it "returns 'No description available'" do
        expect(decorated_test_result.attachment_description).to eq("No description available")
      end
    end

    context "when document is nil" do
      before do
        allow(test_result).to receive(:document).and_return(nil)
      end

      it "returns 'No description available'" do
        expect(decorated_test_result.attachment_description).to eq("No description available")
      end
    end
  end

  describe "#date_of_activity" do
    before { test_result.date = Date.new(2024, 1, 1) }

    it "returns the formatted date" do
      expect(decorated_test_result.date_of_activity).to eq("1 January 2024")
    end
  end

  describe "#event_type" do
    context "when test result passed" do
      let(:result_type) { "passed" }

      it "returns 'Pass'" do
        expect(decorated_test_result.event_type).to eq("Pass")
      end
    end

    context "when test result failed" do
      let(:result_type) { "failed" }

      it "returns 'Fail'" do
        expect(decorated_test_result.event_type).to eq("Fail")
      end
    end
  end

  describe "#is_attached_to_versioned_product?" do
    context "when investigation is closed" do
      before { allow(test_result.investigation_product).to receive(:investigation_closed_at).and_return(Time.zone.now) }

      it "returns true" do
        expect(decorated_test_result.is_attached_to_versioned_product?).to be(true)
      end
    end

    context "when investigation is not closed" do
      before { allow(test_result.investigation_product).to receive(:investigation_closed_at).and_return(nil) }

      it "returns false" do
        expect(decorated_test_result.is_attached_to_versioned_product?).to be(false)
      end
    end
  end
end
