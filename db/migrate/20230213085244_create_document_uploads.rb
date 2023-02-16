class CreateDocumentUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :document_uploads do |t|
      t.json :metadata
      t.references :upload_model, polymorphic: true, index: true
      t.timestamps
    end
  end
end
