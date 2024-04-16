class CreateCreatorUsersFromUserSource < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      # NOTE: UserSource was removed in https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/pull/2051
      # This was an irreversable migration for one time use but is kept for now to ensure it can be reversed
      if defined?(UserSource)
        UserSource.transaction do
          UserSource.where(sourceable_type: "Investigation").find_each do |us|
            user = us.user
            next unless user

            Collaboration::CreatorUser.create!(investigation_id: us.sourceable_id, collaborator_id: us.user_id, collaborator_type: User)
            team = us.user.team
            if team
              Collaboration::CreatorTeam.create!(investigation_id: us.sourceable_id, collaborator_id: team.id, collaborator_type: Team)
            end
          end
        end
      end
    end
  end
end
