class AddInvestigationBusinessToBulkProductsUploads < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :bulk_products_uploads, :investigation_business, index: { algorithm: :concurrently }
  end
end
