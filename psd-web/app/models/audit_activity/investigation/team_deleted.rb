class AuditActivity::Investigation::TeamDeleted < AuditActivity::Investigation::Base
  def self.build_metadata(team, message)
    {
      team: {
        id: team.id,
        name: team.display_name
      },
      message: message
    }
  end

private

  # This is handled by RemoveTeamFromCase, but this override is required to
  # prevent a duplicate investigation_updated email being enqueued, which will
  # fail
  def notify_relevant_users; end
end
