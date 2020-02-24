# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    safety_assured do
      change_table :users do |t|
        ## Database authenticatable
        t.string :encrypted_password, null: false, default: ""

        ## Recoverable
        t.string   :reset_password_token
        t.datetime :reset_password_sent_at

        ## Rememberable
        t.datetime :remember_created_at

        ## Trackable
        t.integer  :sign_in_count, default: 0, null: false
        t.datetime :current_sign_in_at
        t.datetime :last_sign_in_at
        t.inet     :current_sign_in_ip
        t.inet     :last_sign_in_ip
      end

      add_index :users, :reset_password_token, unique: true
    end
  end
  # rubocop:enable Rails/BulkChangeTable
end
