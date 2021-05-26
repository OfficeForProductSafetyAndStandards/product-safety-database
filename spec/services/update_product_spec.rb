require "rails_helper"

RSpec.describe UpdateProduct, :with_elasticsearch, :with_stubbed_mailer do
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
      let(:perform_product_search) { Product.full_search(ElasticsearchQuery.new(product_params[:name], {}, {})) }

      it "updates the product", :aggregate_failures do
        expect(result).to be_a_success

        expect(product.reload).to have_attributes(product_params)
      end

      it "reindexes the product" do
        expect(product.__elasticsearch__).to receive(:update_document)
        result
      end

      it "reindexes the product's investigations" do
        expect(product.investigations).to receive(:import)
        result
      end
    end
  end
end
