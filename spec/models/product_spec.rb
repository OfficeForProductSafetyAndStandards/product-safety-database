require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product) }

  describe "gtin13 field" do
    context "when setting an empty string" do
      before do
        product.gtin13 = ""
      end

      it "gets converted to nil on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.gtin13).to be_nil
      end
    end

    context "when setting nil" do
      before do
        product.gtin13 = nil
      end

      it "is valid" do
        expect(product).to be_valid
      end
    end

    context "when setting an invalid alphanumeric code" do
      before do
        product.gtin13 = "ABC123"
      end

      it "is invalid" do
        expect(product).not_to be_valid
      end
    end

    context "when setting a 12 digit UPC-A code" do
      before do
        product.gtin13 = "012345678912"
      end

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.gtin13).to eq "0012345678912"
      end
    end

    context "when setting a 13 digit EAN code with a trailing space" do
      before do
        product.gtin13 = "0012345678912 "
      end

      it "gets its trailing space removed on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.gtin13).to eq "0012345678912"
      end
    end

    context "when setting a 14 digit GTIN number" do
      before do
        product.gtin13 = "00016000275263"
      end

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.gtin13).to eq "0016000275263"
      end
    end
  end

  describe "brand field" do
    context "when setting an empty string" do
      before do
        product.brand = " "
      end

      it "gets converted to nil on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.brand).to be_nil
      end
    end

    context "when setting as a non-empty string" do
      before do
        product.brand = " MyBrand "
      end

      it "is valid and whitespace is trimmed", :aggregate_failures do
        expect(product).to be_valid
        expect(product.brand).to eq "MyBrand"
      end
    end
  end
end
