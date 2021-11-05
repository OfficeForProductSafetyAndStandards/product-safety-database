class AddLockedReasonToUsers < ActiveRecord::Migration[6.1]
  def change
    create_enum "account_locked_reasons", %w[failed_attempts inactivity]
    add_column :users, :locked_reason, :account_locked_reasons
  end
end
