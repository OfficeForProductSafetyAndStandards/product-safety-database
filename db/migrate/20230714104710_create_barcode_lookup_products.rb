class CreateBarcodeLookupProducts < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :barcode_lookup_products do |t|
        t.integer :product_id
        t.string :barcode_number

        t.string :barcode_formats # SPIKE - this is a string, but should stored as JSON ?

        t.string :mpn
        t.string :model
        t.string :asin
        t.string :title
        t.string :category
        t.string :manufacturer
        t.string :brand
        t.string :contributors
        t.string :age_group
        t.string :ingredients
        t.string :nutrition_facts
        t.string :energy_efficiency_class
        t.string :color
        t.string :gender
        t.string :material
        t.string :pattern
        t.string :format
        t.string :multipack
        t.string :size
        t.string :length
        t.string :width
        t.string :height
        t.string :weight
        t.datetime :release_date
        t.string :description
        t.string :images
        t.datetime :last_api_update_at

        t.timestamps
      end

      add_index :barcode_lookup_products, :barcode_number, unique: true, name: "index_barcode_lookup_products_on_barcode_number"

    end
  end
end
