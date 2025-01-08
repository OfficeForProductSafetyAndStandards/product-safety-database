class AddImageUploadIdsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :image_upload_ids, :bigint, array: true, default: []
  end
end
