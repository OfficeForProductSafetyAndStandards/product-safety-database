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

  def title(_viewer)
    I18n.t(".title", scope: self.class.i18n_scope, team_name: metadata["team"]["name"], case_type: investigation.case_type.downcase)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: self.class.i18n_scope, user_name: source&.show(viewer), date: pretty_date_stamp)
  end

private

  # This is handled by RemoveTeamFromCase, but this override is required to
  # prevent a duplicate investigation_updated email being enqueued, which will
  # fail
  def notify_relevant_users; end
end
