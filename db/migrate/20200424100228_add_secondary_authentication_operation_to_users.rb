class AddSecondaryAuthenticationOperationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :secondary_authentication_operation, :string
  end
end
