require "rails_helper"

RSpec.describe UpdateProduct, :with_opensearch, :with_stubbed_mailer do
  subject(:result) { described_class.call(product:, product_params:, updating_team:) }

  let(:investigation)  { create(:allegation) }
  let(:product)        { create(:product, investigations: [investigation]) }
  let(:product_params) { attributes_for(:product) }
  let(:updating_team)  { create(:team) }

  describe "#call" do
    context "without a product" do
      let(:product) { nil }

      it { is_expected.to be_a_failure }
    end

    context "without product_params" do
      let(:product_params) { nil }

      it { is_expected.to be_a_failure }
    end

    context "without updating_team" do
      let(:updating_team) { nil }

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

      # rubocop:disable RSpec/VerifiedDoubles
      it "reindexes the product's investigations" do
        not_deleted = spy("investigations")
        allow(product.investigations).to receive(:not_deleted) { not_deleted }
        result
        expect(not_deleted).to have_received(:import)
      end
      # rubocop:enable RSpec/VerifiedDoubles

      it "sets the updating team as the product owner" do
        result
        expect(product.reload.owning_team).to eq(updating_team)
      end
    end

    context "with a product owned by another team" do
      let(:product) { create(:product, investigations: [investigation], owning_team: create(:team)) }

      it "updates the product", :aggregate_failures do
        expect(result).to be_a_success

        expect(product.reload).to have_attributes(product_params)
      end
    end

    context "with a product owned by the updating team" do
      let(:product) { create(:product, investigations: [investigation], owning_team: updating_team) }

      it "updates the product", :aggregate_failures do
        expect(result).to be_a_success

        expect(product.reload).to have_attributes(product_params)
      end
    end
  end
end
