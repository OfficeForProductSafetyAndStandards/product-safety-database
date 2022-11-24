require "rails_helper"

RSpec.describe Product do
  it_behaves_like "a batched search model" do
    let(:factory_name) { :product }
  end

  describe "#psd_ref", :with_stubbed_opensearch do
    let(:id) { 123 }
    let(:product) { create :product, :with_versions, id: }

    it "returns a reference formed with 'psd-' and the product's ID" do
      expect(product.psd_ref).to eq("psd-#{id}")
    end

    context "with timestamp" do
      let(:creation_time) { 1.day.ago }
      let(:timestamp) { creation_time.to_i }

      before do
        travel_to(creation_time) { product }
      end

      context "when case has been closed" do
        it "appends the timestamp" do
          expect(product.paper_trail.previous_version.psd_ref(timestamp:, investigation_was_closed: true)).to eq("psd-#{id}_#{timestamp}")
        end
      end

      context "when case has not been closed" do
        context "with a current instance" do
          it "does not append the timestamp" do
            expect(product.psd_ref(timestamp:)).to eq("psd-#{id}")
          end
        end

        context "with a versioned instance" do
          it "appends the timestamp" do
            expect(product.paper_trail.previous_version.psd_ref(timestamp:)).to eq("psd-#{id}_#{timestamp}")
          end
        end
      end
    end
  end

  describe "#owning_team" do
    let(:product) { build :product }

    it "returns nil for a new product" do
      expect(product.owning_team).to eq(nil)
    end
  end

  describe "#unique_investigation_products", :with_stubbed_opensearch, :with_stubbed_mailer do
    let(:investigation) { create(:allegation) }
    let(:investigation_2) { create(:allegation) }
    let(:product) { create(:product) }

    context "when a product has multiple investigation_products that share the same investigation_product" do
      before do
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: Time.current)
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: Time.current)
        create(:investigation_product, investigation_id: investigation.id, product_id: product.id, investigation_closed_at: nil)
        create(:investigation_product, investigation_id: investigation_2.id, product_id: product.id, investigation_closed_at: nil)
      end

      it "returns only one investigation_product per investigation" do
        expect(product.unique_investigation_products.map(&:investigation_id)).to eq [investigation.id, investigation_2.id]
      end
    end
  end
end
