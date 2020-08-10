class AddDeletedAtToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at, algorithm: :concurrently
  end
end
