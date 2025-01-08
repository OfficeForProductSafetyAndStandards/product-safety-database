class ChangeUserRolesToRoles < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      rename_table :user_roles, :roles

      rename_column :roles, :user_id, :entity_id
      add_column :roles, :entity_type, :string, after: :entity_id, null: false, default: "User"

      change_column_default :roles, :entity_type, from: "User", to: nil

      add_index :roles, %i[entity_id entity_type]
    end
  end
end
