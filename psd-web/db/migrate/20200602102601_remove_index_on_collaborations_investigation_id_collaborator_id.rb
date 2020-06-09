class RemoveIndexOnCollaborationsInvestigationIdCollaboratorId < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_index :collaborations, name: "index_collaborations_on_investigation_id_and_collaborator_id"
      remove_index :collaborations, name: "investigation_collaborator_index"
    end
  end
end
