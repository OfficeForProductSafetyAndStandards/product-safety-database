class AddInvitationTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :invitation_token, :text
    add_column :users, :invited_at, :datetime
  end
end
