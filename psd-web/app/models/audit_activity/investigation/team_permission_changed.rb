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

  def title(_viewer)
    I18n.t(".title", scope: self.class.i18n_scope, team_name: metadata["team"]["name"])
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: self.class.i18n_scope, user_name: source&.show(viewer), date: pretty_date_stamp)
  end

  def new_permission
    I18n.t(".permission.#{metadata['permission']['new']}", scope: self.class.i18n_scope)
  end

  def old_permission
    I18n.t(".permission.#{metadata['permission']['old']}", scope: self.class.i18n_scope)
  end

private

  # This is handled by ChangeCasePermissionLevelForTeam, but this override is
  # required to prevent a duplicate investigation_updated email being enqueued,
  # which will fail
  def notify_relevant_users; end
end
