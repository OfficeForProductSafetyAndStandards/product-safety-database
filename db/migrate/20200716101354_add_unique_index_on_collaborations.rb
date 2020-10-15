class AddUniqueIndexOnCollaborations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      # Fix wrong column 'collaborator_type' being used instead of 'type'

      # rubocop:disable Rails/ReversibleMigration
      remove_index :collaborations, name: "index_collaborations_on_investigation_id_and_collaborator_type"
      # rubocop:enable Rails/ReversibleMigration

      add_index :collaborations, %i[investigation_id collaborator_type], unique: true, where: "type = 'Collaboration::Access::OwnerTeam'"

      # Fixes team being able to be added more than once to a case
      add_index :collaborations, %i[investigation_id collaborator_id], unique: true, where: "type != 'Collaboration::CreatorTeam' AND type != 'Collaboration::CreatorUser'"
    end
  end
end
