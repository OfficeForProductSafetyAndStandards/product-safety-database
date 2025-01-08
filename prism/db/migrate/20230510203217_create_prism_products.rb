class CreatePrismProducts < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_products, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :prism_risk_assessment
        t.string :brand
        t.string :name
        t.string :barcode
        t.string :batch_number
        t.string :has_markings
        t.string :markings, array: true
        t.text :other_markings
        t.string :country_of_origin
        t.string :counterfeit
        t.string :risk_tolerability
        t.timestamps
      end
    end
  end
end
