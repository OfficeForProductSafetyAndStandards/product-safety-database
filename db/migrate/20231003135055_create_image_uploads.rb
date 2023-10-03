class CreateImageUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :image_uploads do |t|
      t.uuid :created_by
      t.references :upload_model, polymorphic: true, index: true
      t.timestamps
    end
  end
end
