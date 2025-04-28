class AddUniqueIndexToProductSubcategories < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :product_subcategories, %i[name product_category_id], unique: true, algorithm: :concurrently
  end
end
