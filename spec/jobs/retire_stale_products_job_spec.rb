require "rails_helper"

RSpec.describe RetireStaleProductsJob do
  describe "#perform", :with_stubbed_opensearch do
    subject(:job) { described_class.new }

    context "when there are products to be retired" do
      let!(:products_to_retire) { create_list(:product, 5, created_at: (3.months + 1.day).ago) }

      it "marks all the products as retired", :aggregate_failures do
        freeze_time do
          job.perform
          products_to_retire.each(&:reload)
          expect(products_to_retire.pluck(:retired_at)).to all(eq Time.current)
          expect(products_to_retire).to all(be_retired)
        end
      end

      context "when there are existing products" do
        let!(:existing_products) { create_list(:product, 5) }

        it "does not retire existing products", :aggregate_failures do
          job.perform
          existing_products.each(&:reload)
          expect(existing_products.pluck(:retired_at)).to all(be_nil)
          expect(existing_products).to all(be_not_retired)
        end
      end
    end
  end
end
