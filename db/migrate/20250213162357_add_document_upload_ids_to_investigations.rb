class AddDocumentUploadIdsToInvestigations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :investigations, :document_upload_ids, :bigint, array: true, default: []
  end
end
