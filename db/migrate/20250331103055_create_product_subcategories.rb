class CreateProductSubcategories < ActiveRecord::Migration[7.1]
  def change
    create_table :product_subcategories do |t|
      t.string :name, null: false
      t.references :product_category
      t.timestamps
    end
  end
end
