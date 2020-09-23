class AuditActivity::Investigation::TeamAdded < AuditActivity::Investigation::Base
  def self.build_metadata(collaboration, message)
    team = collaboration.collaborator
    {
      team: {
        id: team.id,
        name: team.display_name
      },
      permission: collaboration.model_name.human,
      message: message
    }
  end

  def team
    Team.find(metadata["team"]["id"])
  end

private

  # This is handled by the AddTeamToCase service, but this override is required
  # to prevent a duplicate investigation_updated email being enqueued, which
  # will fail
  def notify_relevant_users; end
end
