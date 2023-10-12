require "rails_helper"

RSpec.describe FindClosestProductDuplicate, :with_stubbed_mailer do
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
      expect(service.duplicate).to be_nil
    end
  end

  context "when the barcode given has dashes in" do
    let(:barcode) { "1234-567-844" }
    let!(:product) { create(:product, barcode: "1234567844") }

    it "returns the duplicate based on the dashes being stripped out" do
      expect(service.duplicate.id).to eq(product.id)
    end
  end

  context "when there are no duplicates" do
    it "returns no duplicates" do
      expect(service.duplicate).to be_nil
    end
  end

  context "when there are duplicates, but one is counterfeit" do
    let(:barcode) { "1234567890123" }
    let!(:product_a) { create(:product, barcode:, authenticity: "genuine") }

    before do
      create(:product, barcode:, authenticity: "counterfeit")
    end

    it "returns the genuine product only" do
      expect(service.duplicate.id).to eq(product_a.id)
    end
  end

  context "when there are duplicates, one has cases and the other doesn't" do
    let(:barcode) { "1234567890123" }
    let!(:product_a) { create(:product, barcode:) }

    before do
      create_list(:product, 2, barcode:)
      create(:investigation, products: [product_a])
    end

    it "returns the product with cases only" do
      expect(service.duplicate.id).to eq(product_a.id)
    end
  end

  context "when there are duplicates, one has cases and the other doesn't, but the ones without cases are genuine" do
    let(:barcode) { "1234567890123" }
    let!(:product_a) { create(:product, barcode:) }

    before do
      create_list(:product, 2, barcode:, authenticity: "genuine")
      create(:investigation, products: [product_a])
    end

    it "returns the product with cases only" do
      expect(service.duplicate.id).to eq(product_a.id)
    end
  end

  context "when the duplicate of the product is retired" do
    let(:barcode) { "1234567890123" }

    before do
      create(:product, :retired, barcode:)
    end

    it "returns no duplicates" do
      expect(service.duplicate).to be_nil
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
