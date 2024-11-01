class DropAhoyTables < ActiveRecord::Migration[7.1]
  safety_assured do
    remove_reference :investigations, :ahoy_visit, index: true if column_exists?(:investigations, :ahoy_visit_id)
    remove_reference :products, :ahoy_visit, index: true if column_exists?(:products, :ahoy_visit_id)

    drop_table :ahoy_visits if ActiveRecord::Base.connection.table_exists?("ahoy_visits")
    drop_table :ahoy_events if ActiveRecord::Base.connection.table_exists?("ahoy_events")
  end
end
