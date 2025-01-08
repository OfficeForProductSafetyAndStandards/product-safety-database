class FixForeignKeyForPrismHarmScenarioSteps < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_harm_scenario_steps, bulk: true do |t|
        t.remove_references :prism_harm_scenario

        t.references :harm_scenario, type: :uuid
      end
    end
  end
end
