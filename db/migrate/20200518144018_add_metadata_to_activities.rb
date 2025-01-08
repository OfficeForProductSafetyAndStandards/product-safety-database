class AddMetadataToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :metadata, :jsonb
  end
end
