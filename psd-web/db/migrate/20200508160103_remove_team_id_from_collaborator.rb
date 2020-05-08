class RemoveTeamIdFromCollaborator < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      change_column :collaborators, :team_id, :uuid, null: true
    end
  end

  def down
    safety_assured do
      change_column :collaborators, :team_id, :uuid, null: false
    end
  end
end
