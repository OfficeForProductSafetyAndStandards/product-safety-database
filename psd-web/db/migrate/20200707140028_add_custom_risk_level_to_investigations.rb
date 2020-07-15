class AddCustomRiskLevelToInvestigations < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :investigations, :custom_risk_level, :string
    add_index :investigations, :custom_risk_level, algorithm: :concurrently
  end
end
