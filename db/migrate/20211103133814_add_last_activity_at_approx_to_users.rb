class AddLastActivityAtApproxToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :last_activity_at_approx, :datetime
    add_index :users, :last_activity_at_approx, algorithm: :concurrently

    safety_assured do
      User.update_all("last_activity_at_approx=last_sign_in_at")
    end
  end
end
