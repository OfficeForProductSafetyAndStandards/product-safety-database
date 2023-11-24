class AddFieldsToPrismEvaluations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_evaluations, bulk: true do |t|
        t.text :people_at_increased_risk_details
        t.remove :other_hazards, type: :boolean
        t.string :other_hazards
      end
    end
  end
end
