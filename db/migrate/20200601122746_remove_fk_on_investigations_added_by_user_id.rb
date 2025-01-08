class RemoveFkOnInvestigationsAddedByUserId < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_foreign_key "collaborations", column: "added_by_user_id", to_table: "users"
      remove_foreign_key "collaborations", column: "collaborator_id", to_table: "teams"
    end
  end
end
