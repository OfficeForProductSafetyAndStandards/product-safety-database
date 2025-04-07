require "rails_helper"

RSpec.describe ProductCategory do
  subject(:product_category) { build(:product_category, name:) }

  let(:name) { Faker::Restaurant.name }

  describe "#valid?" do
    context "with valid name" do
      it "returns true" do
        expect(product_category).to be_valid
      end
    end

    context "with blank name" do
      let(:name) { nil }

      it "returns false" do
        expect(product_category).not_to be_valid
      end
    end

    context "with duplicate name" do
      before do
        create(:product_category, name:)
      end

      it "returns false" do
        expect(product_category).not_to be_valid
      end
    end
  end

  context "when there are multiple product categories" do
    before do
      create(:product_category, name: "b")
      create(:product_category, name: "d")
      create(:product_category, name: "a")
      create(:product_category, name: "c")
    end

    it "returns them in alphabetical order" do
      expect(described_class.all.pluck(:name)).to eq(%w[a b c d])
    end
  end
end
