class ValidateUsersTeamsKey < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key :users, :teams
  end
end
