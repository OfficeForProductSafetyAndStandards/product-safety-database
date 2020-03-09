class AddKeycloakImportFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table(:users, bulk: true) do |t|
        t.string :keycloak_first_name
        t.string :keycloak_last_name
        t.string :keycloak_username
        t.datetime :keycloak_created_at
      end
    end
  end
end
