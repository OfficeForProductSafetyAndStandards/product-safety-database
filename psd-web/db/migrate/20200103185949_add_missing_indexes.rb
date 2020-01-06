class AddMissingIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :sources, %i[sourceable_id sourceable_type], algorithm: :concurrently
    add_index :investigations, :updated_at, algorithm: :concurrently
  end
end
