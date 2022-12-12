class AddDeletedAtAndDeletedByToInvestigations < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :investigations, :deleted_at, :datetime
    add_index :investigations, :deleted_at, algorithm: :concurrently
    add_column :investigations, :deleted_by, :string
  end
end
