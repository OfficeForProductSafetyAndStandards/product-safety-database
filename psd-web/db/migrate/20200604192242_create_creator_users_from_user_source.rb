class CreateCreatorUsersFromUserSource < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      UserSource.transaction do
        UserSource.where(sourceable_type: "Investigation").each do |us|
          Collaboration::CreatorUser.create!(investigation_id: us.sourceable_id, collaborator_id: us.user_id, collaborator_type: User)
          team = us.user.team
          Collaboration::CreatorTeam.create!(investigation_id: us.sourceable_id, collaborator_id: team.id, collaborator_type: Team)
        end
      end
    end
  end
end
