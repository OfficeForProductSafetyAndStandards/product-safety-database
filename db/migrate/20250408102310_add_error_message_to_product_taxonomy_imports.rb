class AddErrorMessageToProductTaxonomyImports < ActiveRecord::Migration[7.1]
  def change
    add_column :product_taxonomy_imports, :error_message, :string
  end
end
