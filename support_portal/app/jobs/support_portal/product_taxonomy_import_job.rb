module SupportPortal
  class ProductTaxonomyImportJob < ApplicationJob
    def perform(product_taxonomy_import_id)
      product_taxonomy_import = ::ProductTaxonomyImport.find(product_taxonomy_import_id)
      UpdateProductTaxonomy.call(product_taxonomy_import: product_taxonomy_import)
    end
  end
end
