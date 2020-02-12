class CreateUserRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :user_roles do |t|
      t.belongs_to :user, type: :uuid
      t.string :name, null: false
      t.timestamps
    end

    add_index :user_roles, %i[user_id name], unique: true
  end
end
