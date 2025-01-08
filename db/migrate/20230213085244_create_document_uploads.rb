class CreateDocumentUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :document_uploads do |t|
      t.string :title
      t.string :description
      t.uuid :created_by
      t.references :upload_model, polymorphic: true, index: true
      t.timestamps
    end
  end
end
