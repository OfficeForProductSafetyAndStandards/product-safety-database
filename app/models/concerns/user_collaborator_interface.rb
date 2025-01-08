module UserCollaboratorInterface
  extend ActiveSupport::Concern

  def user
    self
  end

  # Do not use on its own. Use ChangeNotificationOwner service class
  def own!(investigation)
    investigation.owner_user_collaboration&.destroy!
    investigation.create_owner_user_collaboration!(collaborator: self)

    investigation.owner_team_collaboration&.destroy!
    investigation.create_owner_team_collaboration!(collaborator: team)
  end

  def in_same_team_as?(user)
    team == user.team
  end
end
