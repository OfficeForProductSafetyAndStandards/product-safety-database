module TeamCollaboratorInterface
  extend ActiveSupport::Concern

  def team
    self
  end

  def user
    nil
  end

  def in_same_team_as?(user)
    users.include?(user)
  end

  def own!(investigation, collaborator = nil)
    if collaborator
      collaborator.update!(type: Collaboration::Access::OwnerTeam)
    else
      investigation.create_owner_team_collaboration!(collaborator: self)
    end
    investigation.owner_user_collaboration&.destroy!
  end
end
