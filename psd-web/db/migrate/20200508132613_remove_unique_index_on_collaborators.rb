class RemoveUniqueIndexOnCollaborators < ActiveRecord::Migration[5.2]
  def change
    remove_index :collaborators, column: %i[investigation_id team_id], unique: true
  end
end
