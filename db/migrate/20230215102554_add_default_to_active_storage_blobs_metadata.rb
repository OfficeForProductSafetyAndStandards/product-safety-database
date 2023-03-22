class AddDefaultToActiveStorageBlobsMetadata < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    change_column_default :active_storage_blobs, :metadata, from: nil, to: "{}"
  end
end
