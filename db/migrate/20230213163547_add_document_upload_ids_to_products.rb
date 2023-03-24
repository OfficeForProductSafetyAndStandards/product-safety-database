class AddDocumentUploadIdsToProducts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :products, :document_upload_ids, :bigint, array: true, default: []
  end
end
