require "rails_helper"

RSpec.describe ProductSubcategory do
  subject(:product_subcategory) { build(:product_subcategory, name:, product_category:) }

  let(:product_category) { build(:product_category, name: Faker::Restaurant.name) }
  let(:name) { Faker::Restaurant.name }

  describe "#valid?" do
    context "with valid name" do
      it "returns true" do
        expect(product_subcategory).to be_valid
      end
    end

    context "with blank name" do
      let(:name) { nil }

      it "returns false" do
        expect(product_subcategory).not_to be_valid
      end
    end

    context "with duplicate name within the same product category" do
      before do
        create(:product_subcategory, name:, product_category:)
      end

      it "returns false" do
        expect(product_subcategory).not_to be_valid
      end
    end

    context "with duplicate name in a different product category" do
      before do
        create(:product_subcategory, name:, product_category: create(:product_category))
      end

      it "returns true" do
        expect(product_category).to be_valid
      end
    end
  end

  context "when there are multiple product subcategories" do
    before do
      create(:product_subcategory, name: "b")
      create(:product_subcategory, name: "d")
      create(:product_subcategory, name: "a")
      create(:product_subcategory, name: "c")
    end

    it "returns them in alphabetical order" do
      expect(described_class.all.pluck(:name)).to eq(%w[a b c d])
    end
  end
end
