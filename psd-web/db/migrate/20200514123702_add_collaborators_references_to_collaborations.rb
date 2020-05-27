class AddCollaboratorsReferencesToCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :collaborations, bulk: true do |t|
        t.column :type, :string, null: false
        t.column :collaborator_type, :string, null: false
      end
      rename_column :collaborations, :team_id, :collaborator_id
      Collaboration.reset_column_information
      Collaboration.update_all(collaborator_type: "Team", type: "Collaborator::EditAccess")
      add_index :collaborations, %i[investigation_id type collaborator_type collaborator_id], name: "investigation_collaborator_index", unique: true
    end
  end
end
