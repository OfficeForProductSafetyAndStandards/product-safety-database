require "support_portal/xlsx_utils"

module SupportPortal
  class ExportProductTaxonomyFile
    include Interactor
    include SupportPortal::XlsxUtils

    delegate :product_taxonomy_import, to: :context

    def call
      context.fail!(error: "No product taxonomy import supplied") unless product_taxonomy_import.is_a?(ProductTaxonomyImport)

      # Create an export file as follows:
      #  One worksheet per category
      #  In each sheet, one column with a list of subcategories for the relevant category
      export_package = Axlsx::Package.new
      export_workbook = export_package.workbook

      ::ProductCategory.all.includes(:product_subcategories).find_each do |product_category|
        export_workbook.add_worksheet(name: worksheet_name(product_category.name)) do |sheet|
          product_category.product_subcategories.each do |product_subcategory|
            sheet.add_row([product_subcategory.name, product_category.name])
          end
        end
      end

      # Create the XLSX
      output_file = serialize_to_file(type: "product_taxonomy_export", axlsx_package: export_package)

      # Attach to the product taxonomy import
      attach_to_model(model: product_taxonomy_import.export_file, file: output_file)

      product_taxonomy_import.mark_as_export_file_created!
    end

  private

    # Worksheet names can be a maximum of 31 characters long without any special characters
    def worksheet_name(name)
      clean_name = name.gsub(/\W+/, " ")

      if clean_name.length > 31
        clean_name[0..28].gsub(/\s\w+\s*$/, "...")
      else
        clean_name
      end
    end
  end
end
