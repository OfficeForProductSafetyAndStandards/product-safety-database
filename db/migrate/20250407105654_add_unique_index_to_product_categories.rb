class AddUniqueIndexToProductCategories < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :product_categories, :name, unique: true, algorithm: :concurrently
  end
end
