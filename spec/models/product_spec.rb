require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product) }

  describe "gtin field" do
    context "when setting an empty string" do
      before do
        product.gtin = ""
      end

      it "gets converted to nil on validation", :aggregate_failures do
        expect(product).to be_valid
        expect(product.gtin).to be_nil
      end
    end

    context "when setting nil" do
      before do
        product.gtin = nil
      end

      it "is valid" do
        expect(product).to be_valid
      end
    end

    context "when setting an invalid alphanumeric code" do
      before do
        product.gtin = "ABC123"
      end

      it "is invalid" do
        expect(product).not_to be_valid
      end
    end

    context "when setting a 12 digit UPC-A code" do
      before do
        product.gtin = "012345678912"
      end

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        product.valid?
        expect(product.gtin).to eq "0012345678912"
      end
    end

    context "when setting a 13 digit EAN code with a trailing space" do
      before do
        product.gtin = "0012345678912 "
      end

      it "gets its trailing space removed on validation" do
        product.valid?
        expect(product.gtin).to eq "0012345678912"
      end
    end

    context "when setting a 14 digit GTIN number" do
      before do
        product.gtin = "00016000275263"
      end

      it "gets converted to a 13 digit code on validation" do
        product.valid?
        expect(product.gtin).to eq "0016000275263"
      end
    end
  end
end
