class CreatePrismHarmScenarioStepEvidences < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # Use integer primary keys rather than UUID to maintain compatibility
      # with the existing Active Storage installation.
      create_table :prism_harm_scenario_step_evidences, force: :cascade do |t|
        t.references :harm_scenario_step, type: :uuid, index: { name: "index_prism_harm_scenario_step_evidences_on_harm_scenario_step" }
        t.timestamps
      end
    end
  end
end
