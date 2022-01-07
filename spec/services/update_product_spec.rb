require "rails_helper"

RSpec.describe UpdateProduct, :with_opensearch, :with_stubbed_mailer do
  subject(:result) { described_class.call(product: product, product_params: product_params) }

  let(:investigation)  { create(:allegation) }
  let(:product)        { create(:product, investigations: [investigation]) }
  let(:product_params) { attributes_for(:product) }

  describe "#call" do
    context "without a product" do
      let(:product) { nil }

      it { is_expected.to be_a_failure }
    end

    context "without product_params" do
      let(:product_params) { nil }

      it { is_expected.to be_a_failure }
    end

    context "with all the required parameters" do
      let(:perform_product_search) { Product.full_search(OpensearchQuery.new(product_params[:name], {}, {})) }

      before do
        allow(product.__elasticsearch__).to receive(:update_document)
        allow(product.investigations).to receive(:import)
      end

      it "updates the product", :aggregate_failures do
        expect(result).to be_a_success

        expect(product.reload).to have_attributes(product_params)
      end

      it "reindexes the product" do
        result
        expect(product.__elasticsearch__).to have_received(:update_document)
      end

      it "reindexes the product's investigations" do
        result
        expect(product.investigations).to have_received(:import)
      end
    end
  end
end
