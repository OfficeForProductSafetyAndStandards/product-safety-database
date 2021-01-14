class RenameGtin13ToBarcode < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      rename_column :products, :gtin13, :barcode
      change_column :products, :barcode, :string, limit: 15
    end
  end
end
