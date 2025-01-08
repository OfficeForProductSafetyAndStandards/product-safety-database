class AddDeletedAtToTeams < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :teams, :deleted_at, :datetime
    add_index :teams, :deleted_at, algorithm: :concurrently
  end
end
