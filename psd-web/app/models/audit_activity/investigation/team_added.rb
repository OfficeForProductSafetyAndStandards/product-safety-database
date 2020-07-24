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

  def title(_viewer)
    I18n.t(".title", scope: self.class.i18n_scope, team_name: metadata["team"]["name"], case_type: investigation.case_type.downcase)
  end

  def subtitle(viewer)
    I18n.t(".subtitle", scope: self.class.i18n_scope, user_name: source&.show(viewer), date: pretty_date_stamp)
  end

  def permission
    I18n.t(".permission.#{metadata['permission']}", scope: self.class.i18n_scope)
  end

private

  # This is handled by the AddTeamToCase service, but this override is required
  # to prevent a duplicate investigation_updated email being enqueued, which
  # will fail
  def notify_relevant_users; end
end
