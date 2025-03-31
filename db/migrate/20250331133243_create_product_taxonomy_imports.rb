class CreateProductTaxonomyImports < ActiveRecord::Migration[7.1]
  def change
    create_table :product_taxonomy_imports do |t|
      t.string :state
      t.references :user
      t.timestamps
    end
  end
end
