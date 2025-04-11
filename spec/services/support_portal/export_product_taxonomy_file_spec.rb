require "rails_helper"

RSpec.describe SupportPortal::ExportProductTaxonomyFile, :with_test_queue_adapter do
  let(:product_taxonomy_import) { create(:product_taxonomy_import) }
  let(:normal_category) { create(:product_category, name: "Short name that is OK") }
  let(:long_category) { create(:product_category, name: "A really long/tenuous name that will be truncated at 31 characters") }
  let(:subcategories_for_normal_category) do
    [
      create(:product_subcategory, product_category: normal_category),
      create(:product_subcategory, product_category: normal_category)
    ]
  end
  let(:subcategories_for_long_category) do
    [
      create(:product_subcategory, product_category: long_category),
      create(:product_subcategory, product_category: long_category)
    ]
  end
  let(:worksheets) do
    product_taxonomy_import.export_file.open do |export_file|
      workbook = RubyXL::Parser.parse(export_file.path)
      workbook.worksheets
    end
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(product_taxonomy_import:) }

      before do
        normal_category
        long_category
        subcategories_for_normal_category
        subcategories_for_long_category
        result
      end

      context "when an XLSX file is generated" do
        it "is attached to the product taxonomy import" do
          expect(product_taxonomy_import.export_file).to be_attached
        end

        it "has one worksheet per product category" do
          expect(worksheets.map(&:sheet_name)).to contain_exactly("Short name that is OK", "A really long tenuous name...")
        end

        it "has the correct number of rows and columns in worksheet 1" do
          expect(worksheets[0].sheet_data.size).to eq(2) # rows
          expect(worksheets[0].sheet_data.rows[0].size).to eq(2) # columns
        end

        it "has the correct number of rows and columns in worksheet 2" do
          expect(worksheets[1].sheet_data.size).to eq(2) # rows
          expect(worksheets[1].sheet_data.rows[0].size).to eq(2) # columns
        end

        it "has the correct data in worksheet 1" do
          expect([worksheets[0].sheet_data.rows[0][0].value, worksheets[0].sheet_data.rows[1][0].value]).to match_array(subcategories_for_normal_category.map(&:name))
          expect([worksheets[0].sheet_data.rows[0][1].value, worksheets[0].sheet_data.rows[1][1].value]).to contain_exactly(normal_category.name, normal_category.name)
        end

        it "has the correct data in worksheet 2" do
          expect([worksheets[1].sheet_data.rows[0][0].value, worksheets[1].sheet_data.rows[1][0].value]).to match_array(subcategories_for_long_category.map(&:name))
          expect([worksheets[1].sheet_data.rows[0][1].value, worksheets[1].sheet_data.rows[1][1].value]).to contain_exactly(long_category.name, long_category.name)
        end
      end
    end
  end
end
