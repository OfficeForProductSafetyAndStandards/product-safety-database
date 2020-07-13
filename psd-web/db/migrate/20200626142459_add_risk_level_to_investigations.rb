class AddRiskLevelToInvestigations < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :investigations, :risk_level, :integer
    add_index :investigations, :risk_level, algorithm: :concurrently
  end
end
