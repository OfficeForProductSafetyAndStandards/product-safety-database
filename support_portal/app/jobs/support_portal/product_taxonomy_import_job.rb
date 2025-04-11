module SupportPortal
  class ProductTaxonomyImportJob < ApplicationJob
    queue_as :"psd-imports"

    retry_on ActiveRecord::RecordNotFound, wait: 5.seconds, attempts: 3
    retry_on StandardError, wait: 30.seconds, attempts: 3

    def perform(product_taxonomy_import_id)
      product_taxonomy_import = ::ProductTaxonomyImport.find(product_taxonomy_import_id)
      product_taxonomy_import.update!(error_message: nil)

      begin
        update_result = UpdateProductTaxonomy.call(product_taxonomy_import: product_taxonomy_import)
        raise(update_result.error) unless update_result.success?

        export_result = ExportProductTaxonomyFile.call(product_taxonomy_import: product_taxonomy_import)
        raise(export_result.error) unless export_result.success?

        template_result = CreateBulkUploadTemplateFile.call(product_taxonomy_import: product_taxonomy_import)
        raise(template_result.error) unless template_result.success?
      rescue StandardError => e
        Rails.logger.error "Product taxonomy import failed for ID: #{product_taxonomy_import_id}: #{e.message}"
        product_taxonomy_import.update!(error_message: e.message)
        raise
      end

      product_taxonomy_import.mark_as_completed!
    end
  end
end
