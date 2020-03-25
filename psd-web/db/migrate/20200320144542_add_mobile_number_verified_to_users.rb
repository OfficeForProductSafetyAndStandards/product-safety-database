class AddMobileNumberVerifiedToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :users, :mobile_number_verified, :boolean, default: false, null: false
    end
  end
end
