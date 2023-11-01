class CreateBulkProductsUploadsProductsJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :bulk_products_uploads, :products
  end
end
