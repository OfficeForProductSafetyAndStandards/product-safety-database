require "rails_helper"

RSpec.describe Product, :with_opensearch do
  it_behaves_like "a batched search model" do
    let(:factory_name) { :product }
  end

  describe "#psd_ref" do
    let(:product) { create :product }

    it "returns a reference formed with 'psd-' and the product's ID" do
      expect(product.psd_ref).to eq("psd-#{product.id}")
    end
  end
end
