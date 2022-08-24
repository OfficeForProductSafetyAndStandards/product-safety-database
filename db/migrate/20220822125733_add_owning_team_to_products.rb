class AddOwningTeamToProducts < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :products, :owning_team, type: :uuid, null: true, index: { algorithm: :concurrently }
    add_foreign_key :products, :teams, column: :owning_team_id, validate: false
  end
end
