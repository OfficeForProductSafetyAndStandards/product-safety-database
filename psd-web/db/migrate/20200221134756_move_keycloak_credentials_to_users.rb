class MoveKeycloakCredentialsToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :users, bulk: true  do
        add_column :users, :password_salt, :binary
        add_column :users, :hash_iterations, :integer, default: 27_500
        add_column :users, :credential_type, :string
      end
    end
  end
end
