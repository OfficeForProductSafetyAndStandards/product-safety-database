class AddActiveFlagToUsers < ActiveRecord::Migration[5.2]
  class User < ApplicationRecord; end

  def up
    add_column :users, :account_activated, :boolean, default: false, index: true

    User.where.not(name: [nil, ""], has_accepted_declaration: false).each do |user|
      user.update(account_activated: true)
    end
  end

  def down
    remove_column :users, :account_activated
  end
end
