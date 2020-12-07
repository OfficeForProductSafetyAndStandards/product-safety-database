class AddIsRiskValidatedToInvestigation < ActiveRecord::Migration[6.0]
  def change
    add_column :investigations, :is_risk_validated, :boolean
  end
end
