class AddEmailUniqueIndexToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    remove_index :users, column: :email, algorithm: :concurrently
    add_index :users, :email, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :users, column: :email, algorithm: :concurrently
    add_index :users, :email, algorithm: :concurrently
  end
end
