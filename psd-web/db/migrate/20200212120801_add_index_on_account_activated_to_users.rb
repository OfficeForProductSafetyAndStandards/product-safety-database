class AddIndexOnAccountActivatedToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :users, :account_activated, algorithm: :concurrently
  end
end
