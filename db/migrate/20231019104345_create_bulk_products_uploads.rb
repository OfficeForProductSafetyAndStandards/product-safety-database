class CreateBulkProductsUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :bulk_products_uploads do |t|
      t.references :investigation
      t.references :user, type: :uuid
      t.timestamps
    end
  end
end
