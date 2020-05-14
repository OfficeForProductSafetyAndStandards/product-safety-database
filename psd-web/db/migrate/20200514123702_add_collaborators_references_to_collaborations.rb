class AddCollaboratorsReferencesToCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_table :collaborations, bulk: true do |t|
        t.column :type, :string, default: "collaborator", null: false
        t.references :collaborator, type: :uuid, index: false, polymorphic: true
      end
      Collaboration.reset_column_information
      add_index :collaborations, %i[investigation_id type collaborator_type collaborator_id], name: "investigation_collaborator_index", unique: true
    end
  end
end
