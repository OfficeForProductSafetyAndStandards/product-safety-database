class AddProductsCacheToBulkProductsUploads < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_products_uploads, :products_cache, :jsonb, default: []
  end
end
