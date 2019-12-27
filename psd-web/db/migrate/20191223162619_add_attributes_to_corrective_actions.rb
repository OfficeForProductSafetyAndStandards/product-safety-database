class AddAttributesToCorrectiveActions < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :corrective_actions, bulk: true do |t|
        t.string :measure_type
        t.string :duration
        t.string :geographic_scope
      end
    end
  end
end
