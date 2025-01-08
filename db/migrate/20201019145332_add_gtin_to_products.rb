class AddGtinToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :gtin13, :string, limit: 13
  end
end
