# This migration comes from prism (originally 20230627092813)
class UpdatePrismTables < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_risk_assessments, bulk: true do |t|
        t.remove :assessed_before, type: :string

        t.string :serious_risk_rebuttable_factors
        t.uuid :created_by_user_id
        t.jsonb :routing_questions
      end

      change_table :prism_products, bulk: true do |t|
        t.remove :counterfeit, type: :string
        t.remove :has_markings, type: :string
        t.remove :markings, type: :string, array: true
        t.remove :other_markings, type: :text
        t.remove :risk_tolerability, type: :string

        t.string :markings
        t.string :category
        t.string :subcategory
        t.text :description
        t.string :placed_on_market_before_eu_exit
        t.jsonb :routing_questions
      end

      change_table :prism_product_market_details, bulk: true do |t|
        t.remove :safety_legislation_standards, type: :string, array: true
        t.remove :other_safety_legislation_standard, type: :string

        t.jsonb :routing_questions
      end

      change_table :prism_harm_scenarios, bulk: true do |t|
        t.remove :supporting_evidence, type: :boolean
      end

      change_table :prism_harm_scenario_steps, bulk: true do |t|
        t.string :probability_type
      end
    end
  end
end
