class AddCollaboratorsReferencesToCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :collaborations do |t|
        t.column :type, :string, default: "collaboration", null: false
        t.column :collaborator_type, :string, null: false
      end
      rename_column :collaborations, :team_id, :collaborator_id
      Collaboration.reset_column_information
      add_index :collaborations, %i[investigation_id type collaborator_type collaborator_id], name: "investigation_collaborator_index", unique: true
    end
  end
end
