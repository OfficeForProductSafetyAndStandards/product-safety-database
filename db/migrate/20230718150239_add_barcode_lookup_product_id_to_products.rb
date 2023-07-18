class AddBarcodeLookupProductIdToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :barcode_lookup_product_id, :integer
  end
end
