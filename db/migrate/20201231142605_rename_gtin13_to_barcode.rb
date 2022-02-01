class RenameGtin13ToBarcode < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      rename_column :products, :gtin13, :barcode
      # rubocop:disable Rails/ReversibleMigration
      change_column :products, :barcode, :string, limit: 15
      # rubocop:enable Rails/ReversibleMigration
    end
  end
end
