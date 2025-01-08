class RenameTypeToSubcategoryOnProducts < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      rename_column :products, :product_type, :subcategory
    end
  end
end
