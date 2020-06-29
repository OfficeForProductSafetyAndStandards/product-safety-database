class Collaboration < ApplicationRecord
  class Access < Collaboration
    require_dependency "collaboration/access/read_only"
    require_dependency "collaboration/access/edit"

    def self.sorted_by_team_name
      includes(:collaborator, investigation: :creator_team)
        .where(collaborator_type: "Team")
        .order(Arel.sql("CASE collaborations.type WHEN 'Collaboration::Access::OwnerTeam' THEN 1 ELSE 2 END"))
    end
  end
end
