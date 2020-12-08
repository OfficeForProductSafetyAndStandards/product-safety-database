class AddIsRiskValidatedToInvestigation < ActiveRecord::Migration[6.0]
  def change
    add_column :investigations, :risk_validated_by, :string
    add_column :investigations, :risk_validated_at, :datetime
  end
end
