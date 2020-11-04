require "rails_helper"

RSpec.describe ProductsHelper do
  describe "#items_for_authenticity" do
    let(:product) { build(:product, authenticity: authenticity) }
    let(:form) { instance_double(ApplicationFormBuilder, object: product) }

    context "when the product has no authenticity set" do
      let(:authenticity) { nil }

      it "has the not provided option" do
        expect(helper.items_for_authenticity(form)).to include(text: "Not provided", value: "missing")
      end
    end

    context "when the product has an authenticity set" do
      let(:authenticity) { Product.authenticities[:genuine] }

      it "does not contain the not provided option" do
        expect(helper.items_for_authenticity(form)).not_to include(text: "Not provided", value: "missing")
      end

      it "has selected the current authenticity" do
        expect(helper.items_for_authenticity(form)).to include(text: "No", value: "genuine", selected: true)
      end
    end

    context "when the product has an authenticity set to missing" do
      let(:authenticity) { Product.authenticities[:missing] }

      it "has the not provided option" do
        expect(helper.items_for_authenticity(form)).to include(text: "Not provided", value: "missing", selected: true)
      end
    end
  end
end
