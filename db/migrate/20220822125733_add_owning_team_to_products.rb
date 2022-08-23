class AddOwningTeamToProducts < ActiveRecord::Migration[6.1]
  def change
    add_reference :products, :owning_team, type: :uuid, null: true, index: false
    add_foreign_key :products, :teams, column: :owning_team_id, validate: false
  end
end
