class CreateUniqueIndexForCollaborationAndOwner < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_index :collaborations, %i[investigation_id collaborator_type], unique: true, where: "collaborator_type = 'Collaboration::Access::OwnerTeam'"
    end
  end
end
