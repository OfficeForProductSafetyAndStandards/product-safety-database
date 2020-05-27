class RenameCollaboratorsToCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_table :collaborators, :collaborations
    end
  end
end
