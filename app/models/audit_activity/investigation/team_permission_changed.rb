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
      message:
    }
  end
end
