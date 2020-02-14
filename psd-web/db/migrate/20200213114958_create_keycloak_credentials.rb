class CreateKeycloakCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :keycloak_credentials do |t|
      t.column :salt, "bytea"
      t.string :encrypted_password
      t.integer :hash_iterations
      t.string :email
      t.string :credential_type

      t.index :email
      t.timestamps
    end
  end
end
