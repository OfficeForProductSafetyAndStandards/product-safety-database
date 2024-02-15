class ChangeAhoyUserIdsToUuids < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_index :ahoy_visits, :user_id
      remove_index :ahoy_events, :user_id

      remove_column :ahoy_visits, :user_id, :bigint
      remove_column :ahoy_events, :user_id, :bigint

      add_reference :ahoy_visits, :user, type: :uuid
      add_reference :ahoy_events, :user, type: :uuid
    end
  end
end
