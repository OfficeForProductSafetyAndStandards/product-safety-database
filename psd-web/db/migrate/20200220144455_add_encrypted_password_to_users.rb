class AddEncryptedPasswordToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :users, :encrypted_password, :text, default: "", null: false
    end
  end
end
