class ChangeProductTaxonomyImportsUserId < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      remove_column :product_taxonomy_imports, :user_id
      add_column :product_taxonomy_imports, :user_id, :uuid
    end
  end

  def down
    safety_assured do
      remove_column :product_taxonomy_imports, :user_id
      add_column :product_taxonomy_imports, :user_id, :bigint
    end
  end
end
