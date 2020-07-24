class Collaboration < ApplicationRecord
  class Access < Collaboration
    require_dependency "collaboration/access/edit"
    require_dependency "collaboration/access/owner"
    require_dependency "collaboration/access/owner_team"
    require_dependency "collaboration/access/owner_user"
    require_dependency "collaboration/access/read_only"

    def self.can_be_changed
      where(type: changeable_classes.map(&:to_s))
    end

    def self.class_from_human_name(human_name)
      changeable_classes.find { |klass| klass.model_name.human == human_name.to_s }
    end

    def self.sorted_by_team_name
      joins("INNER JOIN teams ON teams.id = collaborations.collaborator_id AND collaborations.collaborator_type = 'Team'").includes(investigation: :creator_team)
        .order(Arel.sql("CASE collaborations.type WHEN 'Collaboration::Access::OwnerTeam' THEN 1 ELSE 2 END, teams.name"))
    end

    def can_be_changed?
      self.class.can_be_changed?
    end

    def self.changeable_classes
      descendants.select(&:can_be_changed?)
    end
  end
end
