RSpec.describe ProductsHelper, :with_stubbed_opensearch do
  describe "#items_for_authenticity" do
    let(:product)      { build(:product, authenticity:) }
    let(:product_form) { ProductForm.from(product) }

    context "when the product has no authenticity set" do
      let(:authenticity) { nil }

      context "when creating a product" do
        it "has the not provided option" do
          expect(helper.items_for_authenticity(product_form)).not_to include(text: "Not provided", value: "missing")
        end
      end
    end

    context "when the product has an authenticity set" do
      let(:authenticity) { Product.authenticities[:genuine] }

      it "has selected the current authenticity" do
        expect(helper.items_for_authenticity(product_form)).to include(text: "No", value: "genuine", selected: true)
      end

      context "when the product has an authenticity set to missing" do
        let(:authenticity) { nil }

        before { product.save! }

        it "has the not provided option" do
          expect(helper.items_for_authenticity(product_form).select { |item| item[:selected] == true }).to be_empty
        end
      end
    end
  end
end
