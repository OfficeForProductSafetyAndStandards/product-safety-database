class AddIsRiskValidatedToInvestigation < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      change_table :investigations, bulk: true do |t|
        t.string :risk_validated_by
        t.datetime :risk_validated_at
      end
    end
  end
end
