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
  end
end
