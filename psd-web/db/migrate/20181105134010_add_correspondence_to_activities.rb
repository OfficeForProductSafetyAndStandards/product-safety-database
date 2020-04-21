class AddCorrespondenceToActivities < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_reference :activities, :correspondence, index: false, foreign_key: true
      add_index :activities, :correspondence_id, algorithm: :concurrently
    end
  end
end
