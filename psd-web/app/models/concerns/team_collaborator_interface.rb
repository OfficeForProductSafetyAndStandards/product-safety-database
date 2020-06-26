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

  def own!(investigation, collaborator = nil)
    if collaborator
      collaborator.update!(type: Collaboration::Access::OwnerTeam)
    else
      investigation.create_owner_team_collaboration!(collaborator: self)
    end
    investigation.owner_user_collaboration&.destroy!
  end
end
