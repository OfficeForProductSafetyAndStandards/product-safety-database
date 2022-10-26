require "rails_helper"

RSpec.describe Product do
  it_behaves_like "a batched search model" do
    let(:factory_name) { :product }
  end

  describe "#psd_ref" do
    let(:id) { 123 }
    let(:product) { build :product, id: }

    it "returns a reference formed with 'psd-' and the product's ID" do
      expect(product.psd_ref).to eq("psd-#{id}")
    end

    context "with timestamp", :with_stubbed_opensearch do
      let(:creation_time) { 1.day.ago }
      let(:timestamp) { creation_time.to_i }

      before do
        travel_to(creation_time) { product.save! }
        product.update!(description: "new description")
      end

      context "with a current instance" do
        it "does not append the timestamp" do
          expect(product.psd_ref(timestamp)).to eq("psd-#{id}")
        end
      end

      context "with a versioned instance" do
        it "appends the timestamp" do
          expect(product.paper_trail.previous_version.psd_ref(timestamp)).to eq("psd-#{id}_#{timestamp}")
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
end
