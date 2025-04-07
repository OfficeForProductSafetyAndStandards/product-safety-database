module SupportPortal
  class UpdateProductTaxonomy
    include Interactor

    delegate :product_taxonomy_import, to: :context

    def call
      context.fail!(error: "No product taxonomy import supplied") unless product_taxonomy_import.is_a?(ProductTaxonomyImport)
      context.fail!(error: "The product taxonomy import does not have an import file") unless product_taxonomy_import.import_file.attached?

      # Update database with new product taxonomy
      product_taxonomy_import.import_file.open do |import_file|
        workbook = RubyXL::Parser.parse(import_file.path)

        ActiveRecord::Base.transaction do
          ::ProductCategory.delete_all
          ::ProductSubcategory.delete_all

          subcategories_to_create = []

          workbook.worksheets[0].sheet_data.rows.each_with_index do |row, index|
            next if index.zero? # skip the header row

            category = row[1].value
            subcategory = row[0].value
            next if category.blank? || subcategory.blank?

            product_category = ::ProductCategory.find_or_create_by!(name: category)
            subcategories_to_create << { name: subcategory, product_category_id: product_category.id }
          end

          ::ProductSubcategory.insert_all(subcategories_to_create)

          product_taxonomy_import.mark_as_database_updated!
        end
      end
    end
  end
end
