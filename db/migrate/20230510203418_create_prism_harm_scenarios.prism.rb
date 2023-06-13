# This migration comes from prism (originally 20230510203328)
class CreatePrismHarmScenarios < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_harm_scenarios, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :prism_risk_assessment
        t.string :hazard_type
        t.text :description
        t.string :severity
        t.boolean :multiple_casualties
        t.boolean :supporting_evidence
        t.string :level_of_uncertainty
        t.boolean :sensitivity_analysis
        t.timestamps
      end
    end
  end
end
