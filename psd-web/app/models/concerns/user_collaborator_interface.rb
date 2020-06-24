module UserCollaboratorInterface
  extend ActiveSupport::Concern

  included do
    belongs_to :team
  end

  def user
    self
  end

  def own!(investigation)
    investigation.create_owner_user_collaboration!(collaborator: self)
    investigation.create_owner_team_collaboration!(collaborator: team)
  end

  def in_same_team_as?(user)
    team == user.team
  end
end
