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

    context "with a valid ean13 code" do
      let(:code) { "01234567" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq(code)
      end
    end

    context "when setting a 12 digit UPC-A code" do
      let(:code) { "012345678912" }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("`0012345678912")
      end
    end

    context "when setting a 13 digit EAN code with a trailing space" do
      let(:code) { "0012345678912 " }

      it "sucessfully set the gtin field" do
        expect(model.gtin).to eq("0012345678912")
      end
    end
  end
end
