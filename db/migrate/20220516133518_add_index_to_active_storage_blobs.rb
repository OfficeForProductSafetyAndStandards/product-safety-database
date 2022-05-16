class AddIndexToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :active_storage_blobs, :metadata, algorithm: :concurrently
  end
end
