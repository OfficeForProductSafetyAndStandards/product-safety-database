class AddSubmittedDateToInvestigations < ActiveRecord::Migration[7.1]
  # Disable the transaction for this migration
  disable_ddl_transaction!

  def change
    add_column :investigations, :submitted_at, :datetime, null: true, default: nil
    add_index :investigations, :submitted_at, algorithm: :concurrently
  end
end
