class CreatePrismProductMarketDetails < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_product_market_details, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :prism_risk_assessment
        t.string :selling_organisation
        t.integer :total_products_sold
        t.string :safety_legislation_standards, array: true
        t.string :other_safety_legislation_standard
        t.timestamps
      end
    end
  end
end
