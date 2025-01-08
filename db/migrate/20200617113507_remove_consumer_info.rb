class RemoveConsumerInfo < ActiveRecord::Migration[5.2]
  def up
    safety_assured { remove_column :correspondences, :has_consumer_info }
  end

  def down
    safety_assured { add_column :correspondences, :has_consumer_info, :boolean, default: false, null: false }
  end
end
