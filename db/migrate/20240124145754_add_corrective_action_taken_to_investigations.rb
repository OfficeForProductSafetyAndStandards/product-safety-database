class AddCorrectiveActionTakenToInvestigations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :investigations, bulk: true do |t|
        t.string :corrective_action_taken
        t.string :corrective_action_not_taken_reason
      end
    end
  end
end
