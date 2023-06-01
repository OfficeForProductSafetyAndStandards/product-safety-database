require "rails_helper"

RSpec.describe FindProductDuplicates, :with_stubbed_opensearch do
  subject(:service) do
    described_class.call(barcode:)
  end

  let(:barcode) { "12345678" }

  it "succeeds" do
    expect(service).to be_a_success
  end

  context "when barcode partially matches" do
    before do
      almost_the_right_barcode = "12345678901"
      create_list(:product, 2, barcode: almost_the_right_barcode)
    end

    it "returns no duplicates (exact matching only)" do
      expect(service.duplicates).to be_empty
    end
  end

  context "when the barcode given has dashes in" do
    let(:barcode) { "1234-567-844" }
    let!(:product) { create(:product, barcode: "1234567844") }

    it "returns the duplicate based on the dashes being stripped out" do
      expect(service.duplicates.pluck(:id)).to match_array([product.id])
    end
  end

  context "when there are no duplicates" do
    it "returns no duplicates" do
      expect(service.duplicates).to be_empty
    end
  end

  context "when there are duplicates" do
    let!(:duplicates) { create_list(:product, 2, barcode:) }

    before do
      create_list(:product, 2, barcode: "87654321") # some non-duplicates
    end

    it "returns the duplicates" do
      expect(service.duplicates.pluck(:id)).to match_array(duplicates.pluck(:id))
    end
  end

  context "when no barcode is supplied" do
    let(:barcode) { nil }

    it "fails", :aggregate_failures do
      expect(service).to be_a_failure
      expect(service.error).to eq("No barcode supplied")
    end
  end
end
