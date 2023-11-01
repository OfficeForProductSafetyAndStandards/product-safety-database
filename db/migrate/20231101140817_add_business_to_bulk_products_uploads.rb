class AddBusinessToBulkProductsUploads < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :bulk_products_uploads, :business, index: { algorithm: :concurrently }
  end
end
