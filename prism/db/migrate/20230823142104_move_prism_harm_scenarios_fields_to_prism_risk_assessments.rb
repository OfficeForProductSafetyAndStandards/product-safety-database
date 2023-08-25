class MovePrismHarmScenariosFieldsToPrismRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_harm_scenarios, bulk: true do |t|
        t.remove :level_of_uncertainty, type: :string
        t.remove :sensitivity_analysis, type: :boolean
      end

      change_table :prism_risk_assessments, bulk: true do |t|
        t.string :level_of_uncertainty
        t.boolean :sensitivity_analysis
      end
    end
  end
end
