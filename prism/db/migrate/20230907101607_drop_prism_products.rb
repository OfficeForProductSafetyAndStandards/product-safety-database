class DropPrismProducts < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      drop_table :prism_products, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :harm_scenario, type: :uuid
        t.string :barcode
        t.string :batch_number
        t.string :brand
        t.string :category
        t.string :country_of_origin
        t.text :description
        t.string :markings
        t.string :name
        t.string :placed_on_market_before_eu_exit
        t.jsonb :routing_questions
        t.string :subcategory
        t.timestamps
      end
    end
  end
end
