class AddImageUploadIdsToInvestigations < ActiveRecord::Migration[7.0]
  def change
    add_column :investigations, :image_upload_ids, :bigint, array: true, default: []
  end
end
