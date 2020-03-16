class AddKeycloakImportFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table(:users, bulk: true) do |t|
        t.datetime :keycloak_created_at
      end
    end
  end
end
