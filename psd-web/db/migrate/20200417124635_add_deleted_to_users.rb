class AddDeletedToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :users, :deleted, :boolean, default: false, null: false
      add_index :users, :deleted
    end
  end
end
