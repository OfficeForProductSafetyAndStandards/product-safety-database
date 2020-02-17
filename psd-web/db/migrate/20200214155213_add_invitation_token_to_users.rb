class AddInvitationTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :users, bulk: true do |t|
        t.text :invitation_token
        t.datetime :invited_at
      end
    end
  end
end
