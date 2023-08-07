# This migration comes from prism (originally 20230717110256)
class ChangeProbabilityFieldsForPrismHarmScenarioSteps < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_harm_scenario_steps, bulk: true do |t|
        t.remove :probability, type: :decimal

        t.decimal :probability_decimal
        t.integer :probability_frequency
      end
    end
  end
end
