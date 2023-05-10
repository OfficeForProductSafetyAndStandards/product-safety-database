# This migration comes from prism (originally 20230510203346)
class CreatePrismHarmScenarioSteps < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_harm_scenario_steps, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :prism_harm_scenario
        t.text :description
        t.decimal :probability
        t.string :probability_evidence
        t.timestamps
      end
    end
  end
end
