require "rails_helper"

RSpec.describe SanitizationHelper do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include SanitizationHelper

      attribute :gtin

      def initialize(*args)
        super
        convert_gtin_to_13_digits(:gtin)
      end
    end
  end

  describe "#convert_gtin_to_13_digits" do
    subject(:model) { model_class.new(gtin: code) }

    context "with a short code code" do
      let(:code) { "12" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq(nil)
      end
    end

    context "with a nil code" do
      let(:code) { nil }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq(nil)
      end
    end

    context "with a valid ean13 code" do
      let(:code) { "978020137962" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("0978020137962")
      end
    end

    context "when setting a UPC-E code" do
      let(:code) { "02345673" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("0023456000073")
      end
    end

    context "when setting a 12 digit UPC-A code" do
      let(:code) { "012345678912" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("0012345678912")
      end
    end

    context "when setting a 13 digit EAN code with a trailing space" do
      let(:code) { "0012345678912 " }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("0012345678912")
      end
    end

    context "when setting a 14 digit GTIN number" do
      let(:code) { "00016000275263" }

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        expect(model.gtin).to eq("0016000275263")
      end
    end
  end
end
