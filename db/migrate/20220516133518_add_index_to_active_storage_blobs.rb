class AddIndexToActiveStorageBlobs < ActiveRecord::Migration[6.1]
  def change
    safety_assured { add_index :active_storage_blobs, :metadata }
  end
end
