class UserInvitedAtNotNull < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      User.where(invited_at: nil).update_all("invited_at=created_at")
      change_column :users, :invited_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end

  def down
    safety_assured do
      change_column :users, :invited_at, :datetime, null: true, default: nil
    end
  end
end
