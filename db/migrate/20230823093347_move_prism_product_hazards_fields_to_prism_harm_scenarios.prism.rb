# This migration comes from prism (originally 20230823093043)
class MovePrismProductHazardsFieldsToPrismHarmScenarios < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_product_hazards, bulk: true do |t|
        t.remove :product_aimed_at, type: :string
        t.remove :product_aimed_at_description, type: :string
        t.remove :unintended_risks_for, type: :string, array: true, default: []
      end

      change_table :prism_harm_scenarios, bulk: true do |t|
        t.string :product_aimed_at
        t.string :product_aimed_at_description
        t.string :unintended_risks_for, array: true, default: []
      end
    end
  end
end
