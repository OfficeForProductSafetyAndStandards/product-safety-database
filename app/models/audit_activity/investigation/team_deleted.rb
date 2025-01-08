class AuditActivity::Investigation::TeamDeleted < AuditActivity::Investigation::Base
  def self.build_metadata(team, message)
    {
      team: {
        id: team.id,
        name: team.display_name
      },
      message:
    }
  end

  def team
    Team.find(metadata["team"]["id"])
  end
end
