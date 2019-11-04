class CreateOrganisations < ActiveRecord::Migration[5.2]
  def change
    create_table :organisations do |t|
      t.string :keycloak_id
      t.string :name
      t.string :path
      t.timestamps

      t.index :keycloak_id
    end
  end
end
