class RemoveDocumentUploadIdsFromInvestigations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured { remove_column :investigations, :document_upload_ids, :bigint, array: true, default: [], if_exists: true }
  end
end
