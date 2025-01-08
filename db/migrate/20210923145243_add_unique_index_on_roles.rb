class AddUniqueIndexOnRoles < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :roles, %i[name entity_type entity_id], unique: true, algorithm: :concurrently
  end
end
