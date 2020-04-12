class CreateSecondaryAuthentications < ActiveRecord::Migration[5.2]
  def change
    create_table :secondary_authentications do |t|
      t.string :direct_otp
      t.string :user_id
      t.string :operation
      t.datetime :direct_otp_sent_at
      t.boolean :authenticated
      t.datetime :authentication_expires_at

      t.timestamps
    end
  end
end
