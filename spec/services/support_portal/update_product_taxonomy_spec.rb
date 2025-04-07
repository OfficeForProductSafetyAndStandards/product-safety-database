require "rails_helper"

RSpec.describe SupportPortal::UpdateProductTaxonomy, :with_test_queue_adapter do
  let(:product_taxonomy_import) { create(:product_taxonomy_import) }
  let(:previous_product_category) { create(:product_category) }
  let(:previous_product_subcategory) { create(:product_subcategory, product_category: previous_product_category) }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no import file attached to the product taxonomy import" do
      let(:result) { described_class.call(product_taxonomy_import:) }

      before do
        product_taxonomy_import.import_file.detach
      end

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(product_taxonomy_import:) }

      before do
        previous_product_category
        previous_product_subcategory
      end

      it "deletes all previous product categories and subcategories" do
        result
        expect(ProductCategory.find_by(name: previous_product_category.name)).to be_nil
        expect(ProductSubcategory.find_by(name: previous_product_category.name)).to be_nil
      end

      it "uploads all product categories and subcategories from the import file" do
        result
        expect(ProductCategory.count).to eq(32)
        expect(ProductSubcategory.count).to eq(2467)
      end
    end
  end
end
