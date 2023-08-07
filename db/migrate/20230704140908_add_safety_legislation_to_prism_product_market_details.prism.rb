# This migration comes from prism (originally 20230704140750)
class AddSafetyLegislationToPrismProductMarketDetails < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_product_market_details, bulk: true do |t|
        t.string :safety_legislation_standards, array: true, default: []
        t.string :other_safety_legislation_standard
      end
    end
  end
end
