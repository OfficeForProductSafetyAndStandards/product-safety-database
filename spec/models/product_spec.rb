require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product, has_markings: has_markings) }

  describe "#has_markings?" do
    context "when has_markings == markings_yes" do
      let(:has_markings) { "markings_yes" }

      it "returns true" do
        expect(product.has_markings?).to be true
      end
    end

    context "when has_markings == markings_no" do
      let(:has_markings) { "markings_no" }

      it "returns false" do
        expect(product.has_markings?).to be false
      end
    end

    context "when has_markings == markings_unknown" do
      let(:has_markings) { "markings_unknown" }

      it "returns false" do
        expect(product.has_markings?).to be false
      end
    end
  end
end
