class AddSubmittedAtToBulkProductsUploads < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_products_uploads, :submitted_at, :datetime, precision: nil
  end
end
