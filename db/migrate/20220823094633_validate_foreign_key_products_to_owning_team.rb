class ValidateForeignKeyProductsToOwningTeam < ActiveRecord::Migration[6.1]
  def change
    validate_foreign_key :products, :teams, column: :owning_team_id
  end
end
