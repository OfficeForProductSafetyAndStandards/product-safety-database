class AddDeletedAtAndDeletedByToInvestigations < ActiveRecord::Migration[6.1]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :investigations, :deleted_at, :datetime
    add_column :investigations, :deleted_by, :string
    # rubocop:enable Rails/BulkChangeTable
  end
end
