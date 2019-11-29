class AddActiveFlagToUsers < ActiveRecord::Migration[5.2]
  class User < ApplicationRecord; end

  def up
    # rubocop:disable Rails/BulkChangeTable
    add_column :users, :account_activated, :boolean, index: true
    change_column_default :users, :account_activated, false
    # rubocop:enable Rails/BulkChangeTable

    User.all.each do |user|
      if user.name.present? && user.has_accepted_declaration?
        user.update!(account_activated: true)
      else
        user.update!(account_activated: false)
      end
    end
  end

  def down
    remove_column :users, :account_activated
  end
end
