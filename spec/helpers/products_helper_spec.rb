require "rails_helper"

RSpec.describe ProductsHelper, :with_stubbed_elasticsearch do
  describe "#items_for_authenticity" do
    let(:product)      { build(:product, authenticity: authenticity) }
    let(:product_form) { ProductForm.from(product) }

    context "when the product has no authenticity set" do
      let(:authenticity) { nil }

      context "when creating a product" do
        it "has the not provided option" do
          expect(helper.items_for_authenticity(product_form)).not_to include(text: "Not provided", value: "missing")
        end
      end

      context "when editing product" do
        before { product.save! }

        context "when the product has no previous authenticity set" do
          it "has the not provided option" do
            expect(helper.items_for_authenticity(product_form)).to include(text: "Not provided", value: "missing")
          end
        end
      end
    end

    context "when the product has an authenticity set" do
      let(:authenticity) { Product.authenticities[:genuine] }

      it "does not contain the not provided option" do
        expect(helper.items_for_authenticity(product_form)).not_to include(text: "Not provided", value: "missing")
      end

      it "has selected the current authenticity" do
        expect(helper.items_for_authenticity(product_form)).to include(text: "No", value: "genuine", selected: true)
      end

      context "when the product has an authenticity set to missing" do
        let(:authenticity) { Product.authenticities[:missing] }

        before { product.save! }

        it "has the not provided option" do
          expect(helper.items_for_authenticity(product_form)).to include(text: "Not provided", value: "missing", selected: true)
        end
      end
    end
  end
end
