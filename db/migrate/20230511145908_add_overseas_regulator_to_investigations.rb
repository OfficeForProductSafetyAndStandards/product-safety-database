class AddOverseasRegulatorToInvestigations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :investigations, bulk: true do |t|
        t.boolean :is_from_overseas_regulator
        t.string :overseas_regulator_country
      end
    end
  end
end
