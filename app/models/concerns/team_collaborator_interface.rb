module TeamCollaboratorInterface
  extend ActiveSupport::Concern

  included do
    alias_attribute :email, :team_recipient_email
  end

  def team
    self
  end

  def user
    nil
  end

  def in_same_team_as?(user)
    users.include?(user)
  end

  # Do not use on its own. Use ChangeNotificationOwner service class
  def own!(investigation)
    investigation.owner_user_collaboration&.destroy!
    investigation.owner_team_collaboration&.destroy!
    investigation.create_owner_team_collaboration!(collaborator: self)
  end
end
