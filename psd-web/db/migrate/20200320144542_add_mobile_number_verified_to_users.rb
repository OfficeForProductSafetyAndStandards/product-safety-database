class AddMobileNumberVerifiedToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :users, :mobile_number_verified, :boolean, default: false, null: false

      # Set all existing mobile numbers as verified
      reversible do |dir|
        dir.up do
          User.where.not(mobile_number: nil).update_all(mobile_number_verified: true)
        end
      end
    end
  end
end
