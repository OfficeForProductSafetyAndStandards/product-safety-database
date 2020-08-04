class AuditActivity::Investigation::TeamPermissionChanged < AuditActivity::Investigation::Base
  def self.build_metadata(team, old_permission, new_permission, message)
    {
      team: {
        id: team.id,
        name: team.display_name
      },
      permission: {
        old: old_permission,
        new: new_permission
      },
      message: message
    }
  end

private

  # This is handled by ChangeCasePermissionLevelForTeam, but this override is
  # required to prevent a duplicate investigation_updated email being enqueued,
  # which will fail
  def notify_relevant_users; end
end
