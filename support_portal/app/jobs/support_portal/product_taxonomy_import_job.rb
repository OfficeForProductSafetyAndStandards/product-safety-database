module SupportPortal
  class ProductTaxonomyImportJob < ApplicationJob
    queue_as :psd_imports

    retry_on ActiveRecord::RecordNotFound, wait: 5.seconds, attempts: 3
    retry_on StandardError, wait: 30.seconds, attempts: 3

    def perform(product_taxonomy_import_id)
      product_taxonomy_import = ::ProductTaxonomyImport.find(product_taxonomy_import_id)
      product_taxonomy_import.update!(error_message: nil)

      begin
        result = UpdateProductTaxonomy.call(product_taxonomy_import: product_taxonomy_import)

        unless result.success?
          Rails.logger.error "Product taxonomy import failed for ID: #{product_taxonomy_import_id}: #{result.error}"
          product_taxonomy_import.update!(error_message: result.error)
        end
      rescue StandardError => e
        Rails.logger.error "Product taxonomy import failed for ID: #{product_taxonomy_import_id}: #{e.message}"
        product_taxonomy_import.update!(error_message: e.message)
        raise
      end
    end
  end
end
