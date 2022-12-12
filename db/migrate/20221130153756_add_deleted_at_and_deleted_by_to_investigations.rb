class AddDeletedAtAndDeletedByToInvestigations < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :investigations, :deleted_at, :datetime
    add_index :investigations, :deleted_at, algorithm: :concurrently
    add_column :investigations, :deleted_by, :string
    # rubocop:enable Rails/BulkChangeTable
  end
end
