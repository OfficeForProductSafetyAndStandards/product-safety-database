class DropAhoyTables < ActiveRecord::Migration[7.1]
  def change
    drop_table :ahoy_visits 
    drop_table :ahoy_events
  end
end
