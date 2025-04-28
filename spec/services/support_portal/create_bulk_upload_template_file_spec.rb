require "rails_helper"

RSpec.describe SupportPortal::CreateBulkUploadTemplateFile, :with_test_queue_adapter do
  let(:product_taxonomy_import) { create(:product_taxonomy_import) }
  let(:normal_category) { create(:product_category, name: "Short name that is OK") }
  let(:long_name_category) { create(:product_category, name: "A really long/tenuous name that will be truncated at 31 characters") }
  let(:subcategories_for_normal_category) do
    [
      create(:product_subcategory, product_category: normal_category),
      create(:product_subcategory, product_category: normal_category)
    ]
  end
  let(:subcategories_for_long_category) do
    [
      create(:product_subcategory, product_category: long_name_category),
      create(:product_subcategory, product_category: long_name_category)
    ]
  end
  let(:visible_worksheets) { ["Non compliance Form"] }
  let(:hidden_worksheets_product_categories) { ["Product categories"] }
  let(:hidden_worksheets) { %w[Countries Markings] }
  let(:all_worksheets) { visible_worksheets + hidden_worksheets_product_categories + hidden_worksheets }
  let(:data_validations) do
    [
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "Master"),
        sqref: [have_attributes(col_range: 1..1, row_range: 3..1144)]
      ),
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "UseList"),
        sqref: [have_attributes(col_range: 2..2, row_range: 3..1144)]
      ),
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "Countries!$A$1:$A$278"),
        sqref: [have_attributes(col_range: 4..4, row_range: 3..1144)]
      ),
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "\"Yes, No, Uncertain\""),
        sqref: [have_attributes(col_range: 11..11, row_range: 3..1144)]
      ),
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "Markings!$A$1:$A$9"),
        sqref: [have_attributes(col_range: 12..12, row_range: 3..1144)]
      ),
      have_attributes(
        type: "list",
        formula1: have_attributes(expression: "\"Yes, No, Unable to ascertain\""),
        sqref: [have_attributes(col_range: 13..13, row_range: 3..1144)]
      )
    ]
  end
  let(:worksheets) do
    product_taxonomy_import.bulk_upload_template_file.open do |bulk_upload_template_file|
      workbook = RubyXL::Parser.parse(bulk_upload_template_file.path)
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
        long_name_category
        subcategories_for_normal_category
        subcategories_for_long_category
        result
      end

      context "when an XLSX file is generated" do
        it "is attached to the product taxonomy import" do
          expect(product_taxonomy_import.bulk_upload_template_file).to be_attached
        end

        it "has four worksheets" do
          expect(worksheets.map(&:sheet_name)).to match_array(all_worksheets)
        end

        it "hides all worksheets except the form worksheet" do
          visible_worksheets.each do |worksheet_name|
            expect(worksheet_by_name(worksheet_name).state).to be_nil
          end

          (hidden_worksheets_product_categories + hidden_worksheets).each do |worksheet_name|
            expect(worksheet_by_name(worksheet_name).state).to eq("hidden")
          end
        end

        it "has the correct number of rows and columns for the form worksheet" do
          expect(worksheet_by_name("Non compliance Form").sheet_data.size).to eq(1145) # rows
          expect(worksheet_by_name("Non compliance Form").sheet_data.rows[3].size).to eq(14) # columns for row 3 (to skip first two rows which have merged cells)
        end

        it "has the correct number of rows and columns for the product categories hidden worksheet" do
          expect(worksheet_by_name("Product categories").sheet_data.size).to eq(3) # rows
          expect(worksheet_by_name("Product categories").sheet_data.rows[0].size).to eq(3) # columns
        end

        it "has the correct number of rows and columns for the other hidden worksheets" do
          hidden_worksheets.each do |worksheet_name|
            expect(worksheet_by_name(worksheet_name).sheet_data.rows[0].size).to eq(1) # columns
          end
        end

        it "has the correct data validations" do
          expect(worksheet_by_name("Non compliance Form").data_validations).to match_array(data_validations)
        end
      end
    end

    def worksheet_by_name(worksheet_name)
      worksheets.find { |worksheet| worksheet.sheet_name == worksheet_name }
    end
  end
end
