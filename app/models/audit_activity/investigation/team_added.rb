class AuditActivity::Investigation::TeamAdded < AuditActivity::Investigation::Base
  def self.build_metadata(collaboration, message)
    team = collaboration.collaborator
    {
      team: {
        id: team.id,
        name: team.display_name
      },
      permission: collaboration.model_name.human,
      message:
    }
  end

  def team
    Team.find(metadata["team"]["id"])
  end
end
